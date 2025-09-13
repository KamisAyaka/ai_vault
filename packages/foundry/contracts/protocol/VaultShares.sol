// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC4626, ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IVaultShares, IERC4626} from "../interfaces/IVaultShares.sol";
import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title VaultSharesV2
 * @dev 基于 ERC-4626 的投资金库合约，使用适配器模式支持多协议资产配置
 * @dev 继承自 ERC4626（基础代币功能）、IVaultShares（自定义接口）、ReentrancyGuard（防重入保护）
 */
contract VaultShares is
    ERC4626, // OpenZeppelin标准ERC4626实现
    IVaultShares, // 自定义VaultShares接口
    ReentrancyGuard, // 防止重入攻击
    Ownable // 所有权控制，用于AI代理访问控制
{
    /*//////////////////////////////////////////////////////////////
                            错误定义
    //////////////////////////////////////////////////////////////*/
    error VaultSharesV2__DepositMoreThanMax(uint256 amount, uint256 max);
    error VaultSharesV2__InvalidGovernanceGuardian();
    error VaultSharesV2__VaultNotActive();
    error VaultSharesV2__SlippageToleranceTooHigh(
        uint256 tolerance,
        uint256 max
    );
    error VaultSharesV2__SlippageToleranceSameAsCurrent();
    error VaultSharesV2__InvalidAdapter();
    error VaultSharesV2__AdapterAlreadyAdded();
    error VaultSharesV2__AdapterNotActive();

    /*//////////////////////////////////////////////////////////////
                            状态变量
    //////////////////////////////////////////////////////////////*/

    struct ProtocolAllocation {
        uint256 percentage; // 分配比例，以基点表示（1/10000）
        bool active; // 是否激活
    }

    IERC20 internal s_counterPartyToken;
    address private immutable i_governanceGuardian; // 治理守护者协议地址
    uint256 private immutable i_DaoCut;
    bool private s_isActive;

    // 协议适配器映射
    mapping(address => IProtocolAdapter) private s_protocolAdapters;
    mapping(address => ProtocolAllocation) private s_protocolAllocations;
    address[] private s_activeAdapters; // 活跃适配器列表

    uint256 private constant ALLOCATION_PRECISION = 1_000;

    /*//////////////////////////////////////////////////////////////
                                 事件
    //////////////////////////////////////////////////////////////*/
    event UpdatedAllocation(address indexed adapter, uint256 percentage);
    event NoLongerActive();
    event FundsInvested();
    event AdapterAdded(address indexed adapter, string protocolName);
    event AdapterRemoved(address indexed adapter);
    event CounterPartyTokenUpdated(
        IERC20 indexed oldToken,
        IERC20 indexed newToken
    );

    /*//////////////////////////////////////////////////////////////
                               修饰符
    //////////////////////////////////////////////////////////////*/

    /// @dev 仅治理守护者协议可调用
    modifier onlyGovernanceGuardian() {
        if (msg.sender != i_governanceGuardian) {
            revert VaultSharesV2__InvalidGovernanceGuardian();
        }
        _;
    }

    /// @dev 仅当金库处于活跃状态时可调用
    modifier isActive() {
        if (!s_isActive) {
            revert VaultSharesV2__VaultNotActive();
        }
        _;
    }

    /**
     * @notice 清算所有协议头寸后重新投资
     * @notice 仅在金库活跃时执行再投资，用于调整仓位
     */
    modifier divestThenInvest() {
        _devestFunds(totalAssets());
        _;
        if (s_isActive) {
            _investFunds(IERC20(asset()).balanceOf(address(this)));
        }
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
        i_governanceGuardian = constructorData.governanceGuardian; // 初始化治理守护者协议
        i_DaoCut = constructorData.DaoCut;
        s_counterPartyToken = constructorData.counterPartyTokenV2;
        s_isActive = true;

        // 初始化分配数据
        s_protocolAllocations[constructorData.aavePool] = ProtocolAllocation({
            percentage: constructorData.allocationData.aaveAllocation,
            active: constructorData.allocationData.aaveAllocation > 0
        });

        // 这里需要实际部署适配器，简化处理
        // 在实际实现中，应该通过工厂模式或依赖注入来创建适配器

        updateHoldingAllocation(constructorData.allocationData);
    }

    /*//////////////////////////////////////////////////////////////
                            协议适配器管理
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 添加新的协议适配器
     * @param adapter 适配器地址
     */
    function addProtocolAdapter(
        IProtocolAdapter adapter
    ) external onlyGovernanceGuardian {
        address adapterAddress = address(adapter);
        if (adapterAddress == address(0)) {
            revert VaultSharesV2__InvalidAdapter();
        }

        if (address(s_protocolAdapters[adapterAddress]) != address(0)) {
            revert VaultSharesV2__AdapterAlreadyAdded();
        }

        s_protocolAdapters[adapterAddress] = adapter;
        s_activeAdapters.push(adapterAddress);

        emit AdapterAdded(adapterAddress, adapter.getName());
    }

    /**
     * @notice 移除协议适配器
     * @param adapterAddress 适配器地址
     */
    function removeProtocolAdapter(
        address adapterAddress
    ) external onlyGovernanceGuardian {
        if (address(s_protocolAdapters[adapterAddress]) == address(0)) {
            revert VaultSharesV2__InvalidAdapter();
        }

        // 从活跃适配器列表中移除
        for (uint i = 0; i < s_activeAdapters.length; i++) {
            if (s_activeAdapters[i] == adapterAddress) {
                s_activeAdapters[i] = s_activeAdapters[
                    s_activeAdapters.length - 1
                ];
                s_activeAdapters.pop();
                break;
            }
        }

        delete s_protocolAdapters[adapterAddress];
        delete s_protocolAllocations[adapterAddress];

        emit AdapterRemoved(adapterAddress);
    }

    /**
     * @notice 更新协议分配比例
     * @param adapterAddress 适配器地址
     * @param percentage 新的分配比例（基点）
     */
    function updateProtocolAllocation(
        address adapterAddress,
        uint256 percentage
    ) external onlyGovernanceGuardian {
        if (address(s_protocolAdapters[adapterAddress]) == address(0)) {
            revert VaultSharesV2__InvalidAdapter();
        }

        s_protocolAllocations[adapterAddress].percentage = percentage;
        s_protocolAllocations[adapterAddress].active = percentage > 0;

        emit UpdatedAllocation(adapterAddress, percentage);
    }

    /*//////////////////////////////////////////////////////////////
                               公共函数
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice 设置金库为非活跃状态（守护者离职）
     * @notice 用户仍可提取资产，但禁止新投资
     */
    function setNotActive() public onlyGovernanceGuardian isActive {
        s_isActive = false;
        emit NoLongerActive();
    }

    /**
     * @notice 更新投资分配比例
     * @param tokenAllocationData 新的分配数据
     */
    function updateHoldingAllocation(
        AllocationData memory tokenAllocationData
    ) public onlyGovernanceGuardian isActive {
        // 在这个简化版本中，我们只处理Aave和Uniswap
        // 实际实现中应该处理所有已注册的适配器
        emit UpdatedAllocation(address(0), tokenAllocationData.aaveAllocation);
    }

    /**
     * @notice 更新金库的交易对
     * @notice 新交易对必须是VaultGuardiansBase批准的代币
     * @param newCounterPartyToken 新的交易对代币
     */
    function updateCounterPartyTokenV2(
        IERC20 newCounterPartyToken
    ) external onlyGovernanceGuardian isActive {
        // 存储旧交易对代币以供事件记录
        IERC20 oldToken = s_counterPartyToken;

        // 更新交易对代币
        s_counterPartyToken = newCounterPartyToken;

        // 发出事件
        emit CounterPartyTokenUpdated(oldToken, newCounterPartyToken);
    }

    /**
     * @notice 守护者更新Uniswap滑点容忍度
     * @param tolerance 新的滑点容忍值（以万分之一为单位）
     * @dev 示例：200 = 2%
     */
    function updateUniswapSlippage(
        uint256 tolerance
    ) external onlyGovernanceGuardian {
        // 在这个简化版本中，我们不直接处理滑点
        // 实际实现中应该找到Uniswap适配器并更新其滑点设置
    }

    /*//////////////////////////////////////////////////////////////
                               存取款逻辑
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev 覆盖 Openzeppelin 的 deposit 实现
     * @dev 向 DAO 和 守护者铸造管理费份额
     */
    function deposit(
        uint256 assets,
        address receiver
    )
        public
        override(ERC4626, IERC4626)
        isActive
        nonReentrant
        returns (uint256)
    {
        if (assets > maxDeposit(receiver)) {
            revert VaultSharesV2__DepositMoreThanMax(
                assets,
                maxDeposit(receiver)
            );
        }

        uint256 shares = previewDeposit(assets);
        // 计算管理费和DAO应得份额
        uint256 governanceShares = (shares * i_DaoCut) / 10000; // 0.1%费用

        // 用户实际获得份额 = 总份额 - 管理费
        uint256 userShares = shares - governanceShares;

        // 铸造份额
        _deposit(_msgSender(), receiver, assets, userShares);

        // 铸造管理费和DAO份额
        _mint(i_governanceGuardian, governanceShares);

        _investFunds(assets);
        return shares;
    }

    /**
     * @dev 覆盖 Openzeppelin 的 mint 实现
     * @dev 向 DAO 和 守护者铸造管理费份额
     */
    function mint(
        uint256 shares,
        address receiver
    )
        public
        override(IERC4626, ERC4626)
        isActive
        nonReentrant
        returns (uint256)
    {
        if (shares > maxMint(receiver)) {
            revert VaultSharesV2__DepositMoreThanMax(shares, maxMint(receiver));
        }

        uint256 assets = previewMint(shares);

        // 用户实际获得份额 = 总份额 - 2*管理费
        uint256 governanceShares = (shares * i_DaoCut) / 10000; // 0.1%费用
        uint256 userShares = shares - governanceShares;

        // 铸造份额
        _deposit(_msgSender(), receiver, assets, userShares);

        // 铸造管理费和DAO份额
        _mint(i_governanceGuardian, governanceShares);

        _investFunds(assets);
        return assets;
    }

    /**
     * @notice 用户赎回资产时销毁对应VGT治理代币
     * @dev 覆盖标准redeem实现
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override(IERC4626, ERC4626) nonReentrant returns (uint256 assets) {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        assets = previewRedeem(shares);

        // 按比例清算投资头寸
        _devestFunds(assets);

        _withdraw(_msgSender(), receiver, owner, assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override(IERC4626, ERC4626) nonReentrant returns (uint256 shares) {
        shares = previewWithdraw(assets);
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        // 按比例清算投资头寸
        _devestFunds(assets);

        _withdraw(_msgSender(), receiver, owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                               内部投资逻辑
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice 根据当前分配配置投资用户资金
     * @param assets 需要投资的资产数量
     */
    function _investFunds(uint256 assets) private {
        if (assets == 0) return;

        // 遍历所有活跃的协议适配器并按比例投资
        for (uint i = 0; i < s_activeAdapters.length; i++) {
            address adapterAddress = s_activeAdapters[i];
            ProtocolAllocation memory allocation = s_protocolAllocations[
                adapterAddress
            ];

            if (allocation.active && allocation.percentage > 0) {
                uint256 amountToInvest = (assets * allocation.percentage) /
                    ALLOCATION_PRECISION;
                if (amountToInvest > 0) {
                    s_protocolAdapters[adapterAddress].invest(
                        IERC20(asset()),
                        amountToInvest
                    );
                }
            }
        }

        emit FundsInvested();
    }

    /**
     * @notice 按配置比例清算投资头寸
     * @param assetsToRedeem 需要取回的资产数量
     */
    function _devestFunds(uint256 assetsToRedeem) private {
        if (assetsToRedeem == 0) return;

        // 遍历所有活跃的协议适配器并按比例撤资
        for (uint i = 0; i < s_activeAdapters.length; i++) {
            address adapterAddress = s_activeAdapters[i];
            ProtocolAllocation memory allocation = s_protocolAllocations[
                adapterAddress
            ];

            if (allocation.active && allocation.percentage > 0) {
                uint256 amountToDivest = (assetsToRedeem *
                    allocation.percentage) / ALLOCATION_PRECISION;
                if (amountToDivest > 0) {
                    s_protocolAdapters[adapterAddress].divest(
                        IERC20(asset()),
                        amountToDivest
                    );
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                               操作函数
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 强制清算并重新平衡投资组合
     * @notice 任何人都可调用但需支付高昂Gas费用
     * @notice 应用场景是守护者调整仓位或者出现问题时紧急熔断
     */
    function rebalanceFunds() public isActive divestThenInvest nonReentrant {}

    /*//////////////////////////////////////////////////////////////
                               视图函数
    //////////////////////////////////////////////////////////////*/
    /**
     * @return 返回 VaultGuardians 协议地址
     */
    function getGovernanceGuardian() external view returns (address) {
        return i_governanceGuardian;
    }

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
        // 1. 获取合约中剩余的底层资产余额
        uint256 baseBalance = IERC20(asset()).balanceOf(address(this));

        // 2. 添加所有协议适配器中的资产价值
        uint256 adaptersValue = 0;
        for (uint i = 0; i < s_activeAdapters.length; i++) {
            address adapterAddress = s_activeAdapters[i];
            adaptersValue += s_protocolAdapters[adapterAddress].getTotalValue(
                IERC20(asset())
            );
        }

        return baseBalance + adaptersValue;
    }
}
