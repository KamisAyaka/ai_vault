// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { ERC4626, ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IVaultShares, IERC4626 } from "../interfaces/IVaultShares.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IProtocolAdapter } from "../interfaces/IProtocolAdapter.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title VaultImplementation
 * @dev 基于 ERC-4626 的投资金库实现合约，支持代理模式
 * @dev 继承自 ERC4626（基础代币功能）、IVaultShares（自定义接口）、ReentrancyGuard（防重入保护）
 * @dev 使用Initializable支持代理模式的初始化
 */
contract VaultImplementation is
    ERC4626, // OpenZeppelin标准ERC4626实现
    IVaultShares, // 自定义VaultShares接口
    ReentrancyGuard, // 防止重入攻击
    Ownable, // 所有权控制，用于AI代理访问控制
    Initializable // 支持代理模式初始化
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            状态变量
    //////////////////////////////////////////////////////////////*/
    uint256 internal constant BASIS_POINTS_DIVISOR = 1e4; // 10000 basis points = 100%
    uint256 internal constant ALLOCATION_PRECISION = 1000;

    uint256 internal s_Fee;
    bool private s_isActive;
    IERC20 private s_asset;
    string private s_name;
    string private s_symbol;

    // 保存当前已分配的适配器和分配比例
    Allocation[] private s_allocations;

    /*//////////////////////////////////////////////////////////////
                                 事件
    //////////////////////////////////////////////////////////////*/
    event NoLongerActive();
    event HoldingAllocationUpdated(Allocation[] allocations);
    event Deposit(uint256 assets, address indexed receiver, uint256 userShares);
    event Redeem(uint256 assets, address indexed receiver, uint256 shares);

    /*//////////////////////////////////////////////////////////////
                            错误定义
    //////////////////////////////////////////////////////////////*/

    error VaultImplementation__DepositMoreThanMax(uint256 amount, uint256 max);
    error VaultImplementation__VaultNotActive();
    error VaultImplementation__InvalidAllocation();
    error VaultImplementation__AlreadyInitialized();

    /*//////////////////////////////////////////////////////////////
                               修饰符
    //////////////////////////////////////////////////////////////*/

    /// @dev 仅当金库处于活跃状态时可调用
    modifier isActive() {
        if (!s_isActive) {
            revert VaultImplementation__VaultNotActive();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               构造函数
    //////////////////////////////////////////////////////////////*/
    constructor() ERC4626(IERC20(address(0))) ERC20("", "") Ownable(msg.sender) {
        // 禁用初始化器，防止直接部署
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                               初始化函数
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 初始化金库（用于代理模式）
     * @param constructorData 构造函数数据
     * @param vaultManager 金库管理者地址
     */
    function initialize(ConstructorData memory constructorData, address vaultManager) external initializer {
        // 设置状态变量
        s_asset = constructorData.asset;
        s_name = constructorData.vaultName;
        s_symbol = constructorData.vaultSymbol;
        s_Fee = constructorData.Fee;
        s_isActive = true;

        // 直接设置owner为vaultManager
        _transferOwnership(vaultManager);
    }

    /*//////////////////////////////////////////////////////////////
                               外部函数（管理员调用部分）
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice 设置金库为非活跃状态
     * @notice 用户仍可提取资产，但禁止新投资
     */
    function setNotActive() external onlyOwner isActive {
        s_isActive = false;
        emit NoLongerActive();
    }

    /**
     * @notice 更新完整的适配器和分配比例列表
     * @param allocations 新的适配器和分配比例列表
     */
    function updateHoldingAllocation(Allocation[] calldata allocations) public override(IVaultShares) onlyOwner {
        // 首先撤回当前所有已分配的投资
        withdrawAllInvestments();

        // 直接替换存储数组（这会在storage中创建一个拷贝）
        s_allocations = allocations;

        uint256 availableAssets = IERC20(asset()).balanceOf(address(this));

        _investFunds(availableAssets);
        emit HoldingAllocationUpdated(allocations);
    }

    /**
     * @notice 部分调整投资分配比例
     * @param divestAdapterIndices 需要撤资的适配器索引数组
     * @param divestAmounts 对应的撤资金额数组
     * @param investAdapterIndices 需要投资的适配器索引数组
     * @param investAllocations 对应的投资分配比例数组
     */
    function partialUpdateHoldingAllocation(
        uint256[] calldata divestAdapterIndices,
        uint256[] calldata divestAmounts,
        uint256[] calldata investAdapterIndices,
        uint256[] calldata investAmounts,
        uint256[] calldata investAllocations
    ) external override(IVaultShares) onlyOwner {
        // 验证输入参数
        uint256 divestLength = divestAdapterIndices.length;
        uint256 investLength = investAdapterIndices.length;
        uint256 allocationsLength = s_allocations.length;

        // 从指定适配器中撤资
        for (uint256 i = 0; i < divestLength; i++) {
            uint256 adapterIndex = divestAdapterIndices[i];
            if (adapterIndex >= allocationsLength) {
                revert VaultImplementation__InvalidAllocation();
            }
            IProtocolAdapter adapter = s_allocations[adapterIndex].adapter;
            adapter.divest(IERC20(asset()), divestAmounts[i]);
        }

        // 更新指定适配器的分配比例并投资
        for (uint256 i = 0; i < investLength; i++) {
            uint256 adapterIndex = investAdapterIndices[i];
            if (adapterIndex >= allocationsLength) {
                revert VaultImplementation__InvalidAllocation();
            }
            uint256 amount = investAmounts[i];
            IProtocolAdapter adapter = s_allocations[adapterIndex].adapter;
            s_allocations[adapterIndex].allocation = investAllocations[i];

            // 在投资前先授权 USDC 给适配器
            IERC20(asset()).forceApprove(address(adapter), amount);
            adapter.invest(IERC20(asset()), amount);
        }
        emit HoldingAllocationUpdated(s_allocations);
    }

    /**
     * @notice 撤回所有已分配的投资
     */
    function withdrawAllInvestments() public onlyOwner {
        // 遍历当前已分配的适配器并撤回所有投资
        uint256 allocationsLength = s_allocations.length;
        for (uint256 i = 0; i < allocationsLength; i++) {
            IProtocolAdapter adapter = s_allocations[i].adapter;

            // 获取在该适配器中的资产总价值
            uint256 valueInAdapter = adapter.getTotalValue(IERC20(asset()));

            // 如果适配器中有资产，则撤回所有资产
            if (valueInAdapter > 0) {
                // 使用一个很大的数值确保完全撤资
                adapter.divest(IERC20(asset()), type(uint256).max);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                               存取款逻辑（用户交互部分）
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev 覆盖 Openzeppelin 的 deposit 实现
     * @dev 向 用户 和 管理员铸造管理费份额
     */
    function deposit(uint256 assets, address receiver)
        public
        override(ERC4626, IERC4626)
        nonReentrant
        isActive
        returns (uint256)
    {
        if (assets > maxDeposit(receiver)) {
            revert VaultImplementation__DepositMoreThanMax(assets, maxDeposit(receiver));
        }

        uint256 shares = previewDeposit(assets);
        // 计算管理费应得份额
        uint256 feeShares = (shares * s_Fee) / BASIS_POINTS_DIVISOR; // 管理费

        // 用户实际获得份额 = 总份额 - 管理费
        uint256 userShares = shares - feeShares;

        // 铸造份额
        _deposit(_msgSender(), receiver, assets, userShares);

        // 铸造管理费份额
        _mint(owner(), feeShares);

        // 根据投资策略分配新资金
        _investFunds(assets);

        emit Deposit(assets, receiver, userShares);

        return userShares;
    }

    /**
     * @dev 覆盖 OpenZeppelin 的 mint 实现
     * @dev 向 DAO 和 管理员铸造管理费份额
     */
    function mint(uint256 shares, address receiver)
        public
        override(IERC4626, ERC4626)
        nonReentrant
        isActive
        returns (uint256)
    {
        if (shares > maxMint(receiver)) {
            revert VaultImplementation__DepositMoreThanMax(shares, maxMint(receiver));
        }

        uint256 assets = previewMint(shares);

        // 计算管理费
        uint256 feeShares = (shares * s_Fee) / BASIS_POINTS_DIVISOR; // 管理费
        uint256 userShares = shares - feeShares;

        // 铸造份额
        _deposit(_msgSender(), receiver, assets, userShares);

        // 铸造管理费份额
        _mint(owner(), feeShares);

        // 根据投资策略分配新资金
        _investFunds(assets);

        emit Deposit(assets, receiver, userShares);

        return assets;
    }

    /**
     * @notice 用户赎回资产
     * @dev 覆盖标准redeem实现
     */
    function redeem(uint256 shares, address receiver, address ownerAddr)
        public
        override(IERC4626, ERC4626)
        nonReentrant
        returns (uint256 assets)
    {
        uint256 maxShares = maxRedeem(ownerAddr);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(ownerAddr, shares, maxShares);
        }

        assets = previewRedeem(shares);

        // 根据投资策略撤回所需资金
        _divestFunds(assets);

        _withdraw(_msgSender(), receiver, ownerAddr, assets, shares);

        emit Redeem(assets, receiver, shares);
    }

    /**
     * @notice 用户提取资产
     * @dev 覆盖标准withdraw实现
     */
    function withdraw(uint256 assets, address receiver, address ownerAddr)
        public
        override(IERC4626, ERC4626)
        nonReentrant
        returns (uint256 shares)
    {
        shares = previewWithdraw(assets);
        uint256 maxAssets = maxWithdraw(ownerAddr);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(ownerAddr, assets, maxAssets);
        }

        // 根据投资策略撤回所需资金
        _divestFunds(assets);

        _withdraw(_msgSender(), receiver, ownerAddr, assets, shares);

        emit Redeem(assets, receiver, shares);
    }

    /*//////////////////////////////////////////////////////////////
                               内部函数
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 根据当前配置的投资策略投资指定资产
     * @param assets 要投资的资产数量
     */
    function _investFunds(uint256 assets) internal {
        uint256 allocationsLength = s_allocations.length;
        // 如果没有配置投资策略或分配比例，则不进行投资
        if (allocationsLength == 0) {
            return;
        }

        // 遍历所有配置的适配器并按分配比例投资
        for (uint256 i = 0; i < allocationsLength; i++) {
            // 计算应投资的资产数量
            uint256 amountToInvest = (assets * s_allocations[i].allocation) / ALLOCATION_PRECISION;

            // 如果投资金额大于0，则调用适配器进行投资
            if (amountToInvest > 0) {
                IProtocolAdapter adapter = s_allocations[i].adapter;
                // 授权适配器使用资产
                IERC20(asset()).forceApprove(address(adapter), amountToInvest);

                // 调用适配器的投资函数
                adapter.invest(IERC20(asset()), amountToInvest);
            }
        }
    }

    /**
     * @notice 根据当前配置的投资策略撤回资金
     * @param assets 需要撤回的资产数量
     */
    function _divestFunds(uint256 assets) internal {
        uint256 allocationsLength = s_allocations.length;
        // 如果没有配置投资策略，则不进行撤资
        if (allocationsLength == 0) {
            return;
        }

        // 根据分配比例从各个适配器中撤资
        for (uint256 i = 0; i < allocationsLength; i++) {
            // 计算应从该适配器撤资的资产数量
            uint256 amountToDivest = (assets * s_allocations[i].allocation) / ALLOCATION_PRECISION;

            // 如果撤资金额大于0，则调用适配器进行撤资
            if (amountToDivest > 0) {
                IProtocolAdapter adapter = s_allocations[i].adapter;
                adapter.divest(IERC20(asset()), amountToDivest);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                               视图函数
    //////////////////////////////////////////////////////////////*/
    /**
     * @return 返回金库是否处于活跃状态
     */
    function getIsActive() external view returns (bool) {
        return s_isActive;
    }

    /**
     * @notice 重写ERC20的name函数，返回金库名称
     */
    function name() public view override(ERC20, IERC20Metadata) returns (string memory) {
        return s_name;
    }

    /**
     * @notice 重写ERC20的symbol函数，返回金库符号
     */
    function symbol() public view override(ERC20, IERC20Metadata) returns (string memory) {
        return s_symbol;
    }

    /**
     * @notice 重写ERC4626的asset函数，返回底层资产
     */
    function asset() public view override(ERC4626, IERC4626) returns (address) {
        return address(s_asset);
    }

    function totalAssets() public view override(ERC4626, IERC4626) returns (uint256) {
        // 获取合约中剩余的底层资产余额
        uint256 assetsInContract = IERC20(asset()).balanceOf(address(this));

        // 计算已分配到各个适配器中的资产总价值
        uint256 assetsInAdapters = 0;
        uint256 allocationsLength = s_allocations.length;
        for (uint256 i = 0; i < allocationsLength; i++) {
            assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()));
        }

        // 总资产 = 合约中的资产 + 适配器中的资产
        return assetsInContract + assetsInAdapters;
    }
}
