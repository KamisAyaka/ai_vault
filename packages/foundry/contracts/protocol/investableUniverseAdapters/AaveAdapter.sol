// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IProtocolAdapter } from "../../interfaces/IProtocolAdapter.sol";
import { IPool } from "../../vendor/AaveV3/IPool.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { WadRayMath } from "../../vendor/AaveV3/WadRayMath.sol";

contract AaveAdapter is IProtocolAdapter, Ownable {
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;

    /*//////////////////////////////////////////////////////////////
                            状态变量
    //////////////////////////////////////////////////////////////*/
    IPool public immutable i_aavePool;

    // 代币地址到金库地址的映射
    mapping(IERC20 => address) private s_tokenToVault;

    /*//////////////////////////////////////////////////////////////
                                 事件
    //////////////////////////////////////////////////////////////*/
    event TokenVaultSet(IERC20 indexed token, address indexed vault);
    event Invested(IERC20 indexed asset, uint256 amount, uint256 aTokenBalance);
    event Divested(IERC20 indexed asset, uint256 requestedAmount, uint256 actualAmount);

    /*//////////////////////////////////////////////////////////////
                            错误定义
    //////////////////////////////////////////////////////////////*/
    error OnlyVaultCanCallThisFunction();
    error AaveAdapter__VaultNotValid(address vault);

    /*//////////////////////////////////////////////////////////////
                               构造函数
    //////////////////////////////////////////////////////////////*/
    constructor(address aavePool) Ownable(msg.sender) {
        i_aavePool = IPool(aavePool);
    }

    /*//////////////////////////////////////////////////////////////
                               外部函数（管理者调用）
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 为特定代币设置金库地址
     * @param token 代币地址
     * @param vault 金库地址
     */
    function setTokenVault(IERC20 token, address vault) external onlyOwner {
        if (vault == address(0)) {
            revert AaveAdapter__VaultNotValid(vault);
        }
        s_tokenToVault[token] = vault;
        emit TokenVaultSet(token, vault);
    }

    /*//////////////////////////////////////////////////////////////
                               外部函数（金库调用）
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice 金库使用该函数将底层资产代币作为借贷金额存入Aave v3
     * @param asset 金库的底层资产代币
     * @param amount 要投资的底层资产代币数量
     */
    function invest(IERC20 asset, uint256 amount) external override returns (uint256) {
        address vault = s_tokenToVault[asset];
        if (msg.sender != vault) {
            revert OnlyVaultCanCallThisFunction();
        }

        // 将资金从金库转移到适配器
        asset.safeTransferFrom(msg.sender, address(this), amount);

        asset.forceApprove(address(i_aavePool), amount);
        i_aavePool.supply({
            asset: address(asset),
            amount: amount,
            onBehalfOf: address(this), // aToken发送到适配器
            referralCode: 0
        });

        // 获取aToken地址和余额用于事件
        address aTokenAddress = i_aavePool.getReserveData(address(asset)).aTokenAddress;
        uint256 aTokenBalance = IERC20(aTokenAddress).balanceOf(address(this));

        emit Invested(asset, amount, aTokenBalance);
        return amount;
    }

    /**
     * @notice 金库使用该函数提取其作为借贷金额存入Aave v3的底层资产代币
     * @param token 要提取的金库底层资产代币
     * @param amount 要提取的底层资产代币数量
     */
    function divest(IERC20 token, uint256 amount) external override returns (uint256 amountOfAssetReturned) {
        address vault = s_tokenToVault[token];
        if (msg.sender != vault) {
            revert OnlyVaultCanCallThisFunction();
        }

        // 如果请求的金额是最大值，则提取所有可用资产
        if (amount == type(uint256).max) {
            amountOfAssetReturned = i_aavePool.withdraw({
                asset: address(token),
                amount: type(uint256).max,
                to: address(this) // 资金发送到适配器
             });
        } else {
            amountOfAssetReturned = i_aavePool.withdraw({
                asset: address(token),
                amount: amount,
                to: address(this) // 资金发送到适配器
             });
        }

        // 将回收的资金转回金库
        token.safeTransfer(msg.sender, amountOfAssetReturned);

        emit Divested(token, amount, amountOfAssetReturned);
    }

    /*//////////////////////////////////////////////////////////////
                               视图函数
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 获取金库在Aave中的精确资产价值
     * @param asset 底层资产代币
     * @return 精确的资产价值（以底层资产计价）
     */
    function getTotalValue(IERC20 asset) external view override returns (uint256) {
        // 获取aToken地址
        address aTokenAddress = i_aavePool.getReserveData(address(asset)).aTokenAddress;

        // 获取适配器的aToken余额
        uint256 aTokenBalance = IERC20(aTokenAddress).balanceOf(address(this));

        // 获取储备的标准化收入（流动性指数）
        uint256 normalizedIncome = i_aavePool.getReserveNormalizedIncome(address(asset));

        // 计算精确的资产价值 = aToken余额 * liquidityIndex / RAY (1e27)
        return aTokenBalance.rayMul(normalizedIncome);
    }

    /**
     * @notice 获取适配器名称
     * @return 适配器名称
     */
    function getName() external pure override returns (string memory) {
        return "Aave";
    }
}
