// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IProtocolAdapter} from "../../interfaces/IProtocolAdapter.sol";
import {IPool} from "../../vendor/AaveV3/IPool.sol";
import {DataTypes} from "../../vendor/AaveV3/DataTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {WadRayMath} from "../../vendor/AaveV3/WadRayMath.sol";

contract AaveAdapter is IProtocolAdapter, Ownable {
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;

    IPool public immutable i_aavePool;

    constructor(address aavePool) Ownable(msg.sender) {
        i_aavePool = IPool(aavePool);
    }

    /**
     * @notice 金库使用该函数将底层资产代币作为借贷金额存入Aave v3
     * @param asset 金库的底层资产代币
     * @param amount 要投资的底层资产代币数量
     */
    function invest(
        IERC20 asset,
        uint256 amount
    ) external onlyOwner returns (uint256) {
        asset.forceApprove(address(i_aavePool), amount);
        i_aavePool.supply({
            asset: address(asset),
            amount: amount,
            onBehalfOf: msg.sender, // 决定谁获得Aave的aToken。在此情况下，铸造给金库
            referralCode: 0
        });
        return amount;
    }

    /**
     * @notice 金库使用该函数提取其作为借贷金额存入Aave v3的底层资产代币
     * @param token 要提取的金库底层资产代币
     * @param amount 要提取的底层资产代币数量
     */
    function divest(
        IERC20 token,
        uint256 amount
    ) external onlyOwner returns (uint256 amountOfAssetReturned) {
        amountOfAssetReturned = i_aavePool.withdraw({
            asset: address(token),
            amount: amount,
            to: msg.sender // 直接发送给调用者（金库）
        });
    }

    /**
     * @notice 获取金库在Aave中的精确资产价值
     * @param asset 底层资产代币
     * @return 精确的资产价值（以底层资产计价）
     */
    function getTotalValue(IERC20 asset) external view returns (uint256) {
        // 获取aToken地址
        address aTokenAddress = i_aavePool
            .getReserveData(address(asset))
            .aTokenAddress;

        // 获取金库的aToken余额
        uint256 aTokenBalance = IERC20(aTokenAddress).balanceOf(msg.sender);

        // 获取储备的标准化收入（流动性指数）
        uint256 normalizedIncome = i_aavePool.getReserveNormalizedIncome(
            address(asset)
        );

        // 计算精确的资产价值 = aToken余额 * liquidityIndex / RAY (1e27)
        return aTokenBalance.rayMul(normalizedIncome) / WadRayMath.RAY;
    }

    function getName() external pure override returns (string memory) {
        return "Aave";
    }
}
