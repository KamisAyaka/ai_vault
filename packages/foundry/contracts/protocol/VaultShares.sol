// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC4626, ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IVaultShares, IERC4626} from "../interfaces/IVaultShares.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";

/**
 * @title VaultShares
 * @dev 基于 ERC-4626 的投资金库合约
 * @dev 继承自 ERC4626（基础代币功能）、IVaultShares（自定义接口）、ReentrancyGuard（防重入保护）
 */
contract VaultShares is
    ERC4626, // OpenZeppelin标准ERC4626实现
    IVaultShares, // 自定义VaultShares接口
    ReentrancyGuard, // 防止重入攻击
    Ownable // 所有权控制，用于AI代理访问控制
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            常量定义
    //////////////////////////////////////////////////////////////*/
    uint256 internal constant BASIS_POINTS_DIVISOR = 1e4; // 10000 basis points = 100%

    /*//////////////////////////////////////////////////////////////
                            错误定义
    //////////////////////////////////////////////////////////////*/
    error VaultShares__DepositMoreThanMax(uint256 amount, uint256 max);
    error VaultShares__VaultNotActive();
    error VaultShares__InvalidAllocation();

    /*//////////////////////////////////////////////////////////////
                            状态变量
    //////////////////////////////////////////////////////////////*/

    uint256 private immutable i_Fee;
    uint256 private constant ALLOCATION_PRECISION = 1000;
    bool private s_isActive;

    // 保存当前已分配的适配器列表
    IProtocolAdapter[] private s_allocatedAdapters;

    /*//////////////////////////////////////////////////////////////
                                 事件
    //////////////////////////////////////////////////////////////*/
    event NoLongerActive();
    event HoldingAllocationUpdated(
        IProtocolAdapter[] adapters,
        uint256[] allocations
    );

    /*//////////////////////////////////////////////////////////////
                               修饰符
    //////////////////////////////////////////////////////////////*/

    /// @dev 仅当金库处于活跃状态时可调用
    modifier isActive() {
        if (!s_isActive) {
            revert VaultShares__VaultNotActive();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               构造函数
    //////////////////////////////////////////////////////////////*/
    constructor(
        ConstructorData memory constructorData
    )
        ERC4626(constructorData.asset)
        ERC20(constructorData.vaultName, constructorData.vaultSymbol)
        Ownable(msg.sender) // 初始化Ownable，所有者为部署者
    {
        i_Fee = constructorData.Fee;
        s_isActive = true;
    }

    /*//////////////////////////////////////////////////////////////
                               公共函数
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
     * @notice 更新投资分配比例
     */
    function updateHoldingAllocation(
        IProtocolAdapter[] memory vaultAdapters,
        uint256[] memory allocationData
    ) public override onlyOwner {
        // 首先撤回当前所有已分配的投资
        withdrawAllInvestments();

        // 根据新的分配策略进行投资
        _investInAdapters(vaultAdapters, allocationData);

        // 更新已分配适配器列表
        s_allocatedAdapters = vaultAdapters;

        emit HoldingAllocationUpdated(vaultAdapters, allocationData);
    }

    /**
     * @notice 部分调整投资分配比例
     * @param divestAdapterIndices 需要撤资的适配器索引数组
     * @param divestAmounts 对应的撤资金额数组
     * @param investAdapterIndices 需要投资的适配器索引数组
     * @param investAllocations 对应的投资分配比例数组
     */
    function partialUpdateHoldingAllocation(
        uint256[] memory divestAdapterIndices,
        uint256[] memory divestAmounts,
        uint256[] memory investAdapterIndices,
        uint256[] memory investAllocations
    ) external onlyOwner {
        // 验证输入参数
        uint256 divestLength = divestAdapterIndices.length;
        uint256 investLength = investAdapterIndices.length;

        // 获取当前已分配的适配器列表
        IProtocolAdapter[] memory currentAdapters = s_allocatedAdapters;
        uint256 currentAdaptersLength = currentAdapters.length;

        // 从指定适配器中撤资
        for (uint256 i = 0; i < divestLength; i++) {
            // 检查索引是否有效
            if (divestAdapterIndices[i] >= currentAdaptersLength) {
                revert VaultShares__InvalidAllocation();
            }

            if (divestAmounts[i] > 0) {
                currentAdapters[divestAdapterIndices[i]].divest(
                    IERC20(asset()),
                    divestAmounts[i]
                );
            }
        }

        // 构建要投资的适配器数组
        IProtocolAdapter[] memory investAdapters = new IProtocolAdapter[](
            investLength
        );
        for (uint256 i = 0; i < investLength; i++) {
            // 检查索引是否有效
            if (investAdapterIndices[i] >= currentAdaptersLength) {
                revert VaultShares__InvalidAllocation();
            }

            investAdapters[i] = currentAdapters[investAdapterIndices[i]];
        }

        // 根据新的分配策略进行投资
        _investInAdapters(investAdapters, investAllocations);

        emit HoldingAllocationUpdated(investAdapters, investAllocations);
    }

    /**
     * @notice 撤回所有已分配的投资
     */
    function withdrawAllInvestments() public onlyOwner {
        // 遍历当前已分配的适配器并撤回所有投资
        uint256 adaptersLength = s_allocatedAdapters.length;
        for (uint256 i = 0; i < adaptersLength; i++) {
            IProtocolAdapter adapter = s_allocatedAdapters[i];

            // 获取在该适配器中的资产总价值
            uint256 valueInAdapter = adapter.getTotalValue(IERC20(asset()));

            // 如果适配器中有资产，则撤回所有资产
            if (valueInAdapter > 0) {
                adapter.divest(IERC20(asset()), valueInAdapter);
            }
        }
    }

    /**
     * @notice 在指定适配器中进行投资
     */
    function _investInAdapters(
        IProtocolAdapter[] memory vaultAdapters,
        uint256[] memory allocationData
    ) internal onlyOwner {
        // 获取金库中可用资产总额（合约中的资产）
        uint256 availableAssets = IERC20(asset()).balanceOf(address(this));
        uint256 adaptersLength = vaultAdapters.length;
        // 根据分配比例进行投资
        for (uint256 i = 0; i < adaptersLength; i++) {
            // 计算应投资的资产数量
            uint256 amountToInvest = (availableAssets * allocationData[i]) /
                ALLOCATION_PRECISION;

            // 如果投资金额大于0，则调用适配器进行投资
            if (amountToInvest > 0) {
                // 授权适配器使用资产
                IERC20(asset()).forceApprove(
                    address(vaultAdapters[i]),
                    amountToInvest
                );

                // 调用适配器的投资函数
                vaultAdapters[i].invest(IERC20(asset()), amountToInvest);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                               存取款逻辑
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev 覆盖 Openzeppelin 的 deposit 实现
     * @dev 向 DAO 和 管理员铸造管理费份额
     */
    function deposit(
        uint256 assets,
        address receiver
    )
        public
        override(ERC4626, IERC4626)
        nonReentrant
        isActive
        returns (uint256)
    {
        if (assets > maxDeposit(receiver)) {
            revert VaultShares__DepositMoreThanMax(
                assets,
                maxDeposit(receiver)
            );
        }

        uint256 shares = previewDeposit(assets);
        // 计算管理费和DAO应得份额
        uint256 feeShares = (shares * i_Fee) / BASIS_POINTS_DIVISOR; // 1%费用

        // 用户实际获得份额 = 总份额 - 管理费
        uint256 userShares = shares - feeShares;

        // 铸造份额
        _deposit(_msgSender(), receiver, assets, userShares);

        // 铸造管理费份额
        _mint(owner(), feeShares);

        return shares;
    }

    /**
     * @dev 覆盖 Openzeppelin 的 mint 实现
     * @dev 向 DAO 和 管理员铸造管理费份额
     */
    function mint(
        uint256 shares,
        address receiver
    )
        public
        override(IERC4626, ERC4626)
        nonReentrant
        isActive
        returns (uint256)
    {
        if (shares > maxMint(receiver)) {
            revert VaultShares__DepositMoreThanMax(shares, maxMint(receiver));
        }

        uint256 assets = previewMint(shares);

        // 计算管理费
        uint256 feeShares = (shares * i_Fee) / BASIS_POINTS_DIVISOR; // 1%费用
        uint256 userShares = shares - feeShares;

        // 铸造份额
        _deposit(_msgSender(), receiver, assets, userShares);

        // 铸造管理费份额
        _mint(owner(), feeShares);

        return assets;
    }

    /**
     * @notice 用户赎回资产
     * @dev 覆盖标准redeem实现
     */
    function redeem(
        uint256 shares,
        address receiver,
        address ownerAddr
    ) public override(IERC4626, ERC4626) nonReentrant returns (uint256 assets) {
        uint256 maxShares = maxRedeem(ownerAddr);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(ownerAddr, shares, maxShares);
        }

        assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, ownerAddr, assets, shares);
    }

    /**
     * @notice 用户提取资产
     * @dev 覆盖标准withdraw实现
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address ownerAddr
    ) public override(IERC4626, ERC4626) nonReentrant returns (uint256 shares) {
        shares = previewWithdraw(assets);
        uint256 maxAssets = maxWithdraw(ownerAddr);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(ownerAddr, assets, maxAssets);
        }

        _withdraw(_msgSender(), receiver, ownerAddr, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                               视图函数
    //////////////////////////////////////////////////////
    /**
     * @return 返回金库是否处于活跃状态
     */
    function getIsActive() external view returns (bool) {
        return s_isActive;
    }

    function totalAssets()
        public
        view
        override(ERC4626, IERC4626)
        returns (uint256)
    {
        // 获取合约中剩余的底层资产余额
        uint256 assetsInContract = IERC20(asset()).balanceOf(address(this));

        // 计算已分配到各个适配器中的资产总价值
        uint256 assetsInAdapters = 0;
        uint256 adaptersLength = s_allocatedAdapters.length;
        for (uint256 i = 0; i < adaptersLength; i++) {
            assetsInAdapters += s_allocatedAdapters[i].getTotalValue(
                IERC20(asset())
            );
        }

        // 总资产 = 合约中的资产 + 适配器中的资产
        return assetsInContract + assetsInAdapters;
    }
}
