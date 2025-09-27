// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IVaultShares } from "../interfaces/IVaultShares.sol";
import { IWETH9 } from "../interfaces/IWETH9.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IProtocolAdapter } from "../interfaces/IProtocolAdapter.sol";
import { ERC4626, ERC20, IERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

/**
 * @title VaultSharesETH
 * @dev 专门处理 ETH/WETH 转换的金库合约
 * @dev 继承自 VaultShares，添加 ETH 相关功能
 */
contract VaultSharesETH is ERC4626, IVaultShares, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    /*//////////////////////////////////////////////////////////////
                            常量定义
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant BASIS_POINTS_DIVISOR = 1e4; // 10000 basis points = 100%
    uint256 internal constant ALLOCATION_PRECISION = 1000;

    /*//////////////////////////////////////////////////////////////
                            状态变量
    //////////////////////////////////////////////////////////////*/
    uint256 private immutable i_Fee;
    address private immutable i_WETH; // WETH 合约地址
    bool private s_ethConversionEnabled = true; // 控制是否自动转换 ETH 为 WETH
    bool private s_isActive;

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
    error VaultSharesETH__MustSendETH();
    error VaultSharesETH__InsufficientETHSent();
    error VaultSharesETH__ETHTransferFailed();
    error VaultSharesETH__VaultNotActive();
    error VaultSharesETH__DepositMoreThanMax(uint256 amount, uint256 max);

    /*//////////////////////////////////////////////////////////////
                               修饰符
    //////////////////////////////////////////////////////////////*/

    /// @dev 仅当金库处于活跃状态时可调用
    modifier isActive() {
        if (!s_isActive) {
            revert VaultSharesETH__VaultNotActive();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               构造函数
    //////////////////////////////////////////////////////////////*/
    constructor(IVaultShares.ConstructorData memory constructorData)
        ERC4626(constructorData.asset)
        ERC20(constructorData.vaultName, constructorData.vaultSymbol)
        Ownable(msg.sender)
    {
        i_Fee = constructorData.Fee;
        i_WETH = address(constructorData.asset);
        s_isActive = true;
    }

    /*//////////////////////////////////////////////////////////////
                               外部函数(管理者调用)
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

        // 从指定适配器中撤资
        for (uint256 i = 0; i < divestLength; i++) {
            uint256 adapterIndex = divestAdapterIndices[i];
            IProtocolAdapter adapter = s_allocations[adapterIndex].adapter;
            adapter.divest(IERC20(asset()), divestAmounts[i]);
        }

        // 更新指定适配器的分配比例并投资
        for (uint256 i = 0; i < investLength; i++) {
            uint256 adapterIndex = investAdapterIndices[i];
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
                               外部函数(用户调用)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 接收 ETH 的函数
     * @dev 当用户发送 ETH 到合约时自动调用
     */
    receive() external payable {
        // 如果启用自动转换，则自动将 ETH 转换为 WETH
        if (msg.value > 0 && s_ethConversionEnabled) {
            IWETH9(i_WETH).deposit{ value: msg.value }();
        }
    }

    /**
     * @notice 使用 ETH 进行存款，自动转换为 WETH
     * @dev 向 DAO 和 管理员铸造管理费份额
     */
    function depositETH(address receiver) external payable nonReentrant isActive returns (uint256) {
        if (msg.value == 0) {
            revert VaultSharesETH__MustSendETH();
        }

        uint256 assets = msg.value;
        if (assets > maxDeposit(receiver)) {
            revert VaultSharesETH__DepositMoreThanMax(assets, maxDeposit(receiver));
        }

        // 计算份额 BEFORE 转换 ETH 为 WETH，这样 totalAssets 还是原来的值
        uint256 shares = previewDeposit(assets);

        // 计算管理费和DAO应得份额
        uint256 feeShares = (shares * i_Fee) / BASIS_POINTS_DIVISOR; // 1%费用

        // 用户实际获得份额 = 总份额 - 管理费
        uint256 userShares = shares - feeShares;

        // 直接铸造份额，因为 WETH 已经在合约中
        // 注意：这里我们直接铸造份额，因为资产（WETH）已经通过 ETH 转换在合约中了
        _mint(receiver, userShares);

        // 铸造管理费份额
        _mint(owner(), feeShares);

        // 将 ETH 转换为 WETH (移到状态修改之后)
        IWETH9(i_WETH).deposit{ value: msg.value }();

        // 发出存款事件
        emit Deposit(assets, receiver, userShares);

        // 根据投资策略分配新资金
        _investFunds(assets);

        return userShares;
    }

    /**
     * @notice 使用 ETH 进行铸造，自动转换为 WETH
     * @dev 向 DAO 和 管理员铸造管理费份额
     */
    function mintETH(uint256 shares, address receiver) external payable nonReentrant isActive returns (uint256) {
        if (msg.value == 0) {
            revert VaultSharesETH__MustSendETH();
        }

        if (shares > maxMint(receiver)) {
            revert VaultSharesETH__DepositMoreThanMax(shares, maxMint(receiver));
        }

        uint256 assets = previewMint(shares);
        if (msg.value < assets) {
            revert VaultSharesETH__InsufficientETHSent();
        }

        // 计算管理费
        uint256 feeShares = (shares * i_Fee) / BASIS_POINTS_DIVISOR; // 1%费用
        uint256 userShares = shares - feeShares;

        // 直接铸造份额，因为 WETH 已经在合约中
        _mint(receiver, userShares);

        // 铸造管理费份额
        _mint(owner(), feeShares);
        // 将 ETH 转换为 WETH
        IWETH9(i_WETH).deposit{ value: msg.value }();

        // 发出铸造事件
        emit Deposit(assets, receiver, userShares);

        // 根据投资策略分配新资金
        _investFunds(assets);

        return assets;
    }

    /**
     * @notice 使用 ETH 进行赎回，自动将 WETH 转换为 ETH
     * @dev 专门用于 ETH 退出的函数
     */
    function redeemETH(uint256 shares, address receiver, address ownerAddr)
        external
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

        // 销毁用户的份额
        _burn(ownerAddr, shares);

        // 临时禁用 ETH 自动转换，避免无限循环
        s_ethConversionEnabled = false;

        // 将 WETH 转换为 ETH 并发送给接收者
        IWETH9(i_WETH).withdraw(assets);

        // 重新启用 ETH 自动转换
        s_ethConversionEnabled = true;

        (bool success,) = receiver.call{ value: assets }("");
        if (!success) {
            revert VaultSharesETH__ETHTransferFailed();
        }

        // 发出赎回事件
        emit Redeem(assets, receiver, shares);
    }

    /**
     * @notice 使用 ETH 进行提取，自动将 WETH 转换为 ETH
     * @dev 专门用于 ETH 退出的函数
     */
    function withdrawETH(uint256 assets, address receiver, address ownerAddr)
        external
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

        // 销毁用户的份额
        _burn(ownerAddr, shares);

        // 临时禁用 ETH 自动转换，避免无限循环
        s_ethConversionEnabled = false;

        // 将 WETH 转换为 ETH 并发送给接收者
        IWETH9(i_WETH).withdraw(assets);

        // 重新启用 ETH 自动转换
        s_ethConversionEnabled = true;

        // 安全检查：确保receiver不是零地址
        if (receiver == address(0)) {
            revert VaultSharesETH__ETHTransferFailed();
        }

        // 向接收者发送ETH
        (bool success,) = receiver.call{ value: assets }("");
        if (!success) {
            revert VaultSharesETH__ETHTransferFailed();
        }

        // 发出提取事件
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
