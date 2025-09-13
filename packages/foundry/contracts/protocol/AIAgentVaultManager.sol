// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IVaultShares} from "../interfaces/IVaultShares.sol";
import {VaultShares} from "./VaultShares.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AStaticUSDCData, IERC20} from "../abstract/AStaticUSDCData.sol";
import {VaultGuardianToken} from "../dao/VaultGuardianToken.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ProtocolAdapterFactory} from "./ProtocolAdapterFactory.sol";

/**
 * @title AIAgentVaultManager
 * @notice 为AI代理提供的金库分配参数管理接口
 * @dev 这个合约允许AI代理直接更新金库资产分配策略
 */
contract AIAgentVaultManager is AStaticUSDCData, Ownable {
    using SafeERC20 for IERC20;
    mapping(address vault => bool) private s_validVaults;

    // 金库地址到资产分配数据的映射
    mapping(IERC20 asset => IVaultShares vaultShares) private s_vault;
    mapping(IERC20 token => bool isApproved) private s_isApprovedToken;

    uint256 internal s_DaoCut = 1000;
    address private immutable i_aavePool;
    address private immutable i_uniswapV2Router;
    address private immutable i_uniswapV3Router;
    VaultGuardianToken private immutable i_vgToken;
    ProtocolAdapterFactory private immutable i_adapterFactory;

    event AllocationUpdated(
        address indexed vault,
        IVaultShares.AllocationData allocationData
    );
    event SlippageToleranceUpdated(address indexed vault, uint256 tolerance);
    event VaultCreatedAndRegistered(address indexed vault, string vaultName);
    event VaultEmergencyStopped(address indexed vault);

    error AIAgentVaultManager__VaultNotRegistered(address vault);
    error AIAgentVaultManager__InvalidAllocation();
    error AIAgentVaultManager__InvalidVault(address vaultAddress);
    error AIAgentVaultManager__UnsupportedToken(address token);

    /**
     * @dev 仅允许有效金库调用
     */
    modifier onlyVaultShares() {
        if (!s_validVaults[msg.sender]) {
            revert AIAgentVaultManager__InvalidVault(msg.sender);
        }
        _;
    }

    /**
     * @notice 构造函数
     */
    constructor(
        address aavePool,
        address uniswapV2Router,
        address uniswapV3Router,
        IERC20 tokenOne, // USDT
        IERC20 tokenTwo, // USDC
        address vgToken,
        address adapterFactory
    ) AStaticUSDCData(tokenOne, tokenTwo) Ownable(msg.sender) {
        s_isApprovedToken[tokenOne] = true;
        s_isApprovedToken[tokenTwo] = true;

        i_aavePool = aavePool;
        i_uniswapV2Router = uniswapV2Router;
        i_uniswapV3Router = uniswapV3Router;
        i_vgToken = VaultGuardianToken(vgToken);
        i_adapterFactory = ProtocolAdapterFactory(adapterFactory);
    }

    /**
     * @notice 创建一个新的金库并自动注册
     *
     * @return vaultAddress 新创建的金库地址
     */
    function createVault(
        IVaultShares.AllocationData memory allocationData,
        IERC20 token,
        IERC20 counterPartyTokenV2,
        IERC20 counterPartyTokenV3,
        bool isApprovedtoken
    ) external onlyOwner returns (address vaultAddress) {
        // 部署新的金库合约
        VaultShares tokenVault;

        tokenVault = new VaultShares(
            IVaultShares.ConstructorData({
                asset: token,
                counterPartyTokenV2: counterPartyTokenV2,
                counterPartyTokenV3: counterPartyTokenV3,
                allocationData: allocationData,
                DaoCut: s_DaoCut,
                isApprovedtoken: isApprovedtoken,
                aavePool: i_aavePool,
                uniswapV2Router: i_uniswapV2Router,
                uniswapV3Router: address(0),
                governanceGuardian: address(this),
                vaultName: string.concat(
                    "Vault Guardian ",
                    IERC20Metadata(address(token)).name()
                ),
                vaultSymbol: string.concat(
                    "vg",
                    IERC20Metadata(address(token)).symbol()
                )
            })
        );

        vaultAddress = address(tokenVault);
        s_vault[token] = IVaultShares(vaultAddress);
        if (isApprovedtoken) {
            s_validVaults[vaultAddress] = true;
        }

        emit VaultCreatedAndRegistered(vaultAddress, tokenVault.name());
    }

    /**
     * @notice 更新金库资产分配策略
     * @param token 金库的代币地址
     * @param allocationData 新的资产分配数据
     */
    function updateHoldingAllocation(
        IERC20 token,
        IVaultShares.AllocationData memory allocationData
    ) external onlyOwner {
        // 调用金库的更新函数
        s_vault[token].updateHoldingAllocation(allocationData);

        emit AllocationUpdated(address(s_vault[token]), allocationData);
    }

    /**
     * @notice 更新金库的Uniswap滑点容忍度
     * @param token 金库代币地址
     * @param tolerance 新的滑点容忍度（以万分之一为单位，例如200表示2%）
     */
    function updateUniswapSlippage(
        IERC20 token,
        uint256 tolerance
    ) external onlyOwner {
        address vault = address(s_vault[token]);
        if (vault == address(0)) {
            revert AIAgentVaultManager__VaultNotRegistered(vault);
        }

        // 调用金库的更新函数
        s_vault[token].updateUniswapSlippage(tolerance);

        emit SlippageToleranceUpdated(vault, tolerance);
    }

    /**
     * @notice 更新金库的交易对
     * @notice 新交易对必须是VaultGuardiansBase批准的代币
     * @param token 要更新的管理代币
     * @param newCounterPartyToken 新的交易对代币
     */
    function updateVaultCounterPartyToken(
        IERC20 token,
        IERC20 newCounterPartyToken
    ) external {
        // 验证新交易对代币是否已批准
        if (
            !s_isApprovedToken[newCounterPartyToken] ||
            newCounterPartyToken == token
        ) {
            revert AIAgentVaultManager__UnsupportedToken(
                address(newCounterPartyToken)
            );
        }

        // 调用VaultShares的updateCounterPartyToken
        s_vault[token].updateCounterPartyTokenV2(newCounterPartyToken);
    }

    /// @notice 添加批准代币的内部实现
    /// @param token 要新增的代币地址
    function addApprovedToken(IERC20 token) external onlyOwner {
        if (address(token) == address(0)) {
            revert AIAgentVaultManager__UnsupportedToken(address(0));
        }
        if (s_isApprovedToken[token]) {
            revert AIAgentVaultManager__UnsupportedToken(address(token));
        }
        s_isApprovedToken[token] = true;
    }

    function mintVGT(address to, uint256 amount) external onlyVaultShares {
        i_vgToken.mint(to, amount);
    }

    function burnVGT(address to, uint256 amount) external onlyVaultShares {
        i_vgToken.burn(to, amount);
    }

    /**
     * @notice 紧急停止金库运行
     * @param token 金库代币地址
     */
    function emergencyStopVault(IERC20 token) external onlyOwner {
        address vault = address(s_vault[token]);
        if (vault == address(0)) {
            revert AIAgentVaultManager__VaultNotRegistered(vault);
        }

        // 调用金库的setNotActive函数
        s_vault[token].setNotActive();

        emit VaultEmergencyStopped(vault);
    }

    /**
     * @notice 获取协议适配器工厂实例
     * @return 协议适配器工厂地址
     */
    function getAdapterFactory()
        external
        view
        returns (ProtocolAdapterFactory)
    {
        return i_adapterFactory;
    }
}
