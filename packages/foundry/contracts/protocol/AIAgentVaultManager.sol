// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IVaultShares } from "../interfaces/IVaultShares.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IProtocolAdapter } from "../interfaces/IProtocolAdapter.sol";

/**
 * @title AIAgentVaultManager
 * @notice 为AI代理提供的金库分配参数管理接口
 * @dev 这个合约允许AI代理直接更新金库资产分配策略
 */
contract AIAgentVaultManager is Ownable {
    /*//////////////////////////////////////////////////////////////
                               状态变量
    //////////////////////////////////////////////////////////////*/
    // 金库地址到资产分配数据的映射
    mapping(IERC20 asset => IVaultShares vaultShares) private s_vault;

    // 协议适配器地址到是否批准的映射
    mapping(IProtocolAdapter => bool) private s_approvedAdapters;

    // 全局适配器列表
    IProtocolAdapter[] private s_allAdapters;

    /*//////////////////////////////////////////////////////////////
                               事件
    //////////////////////////////////////////////////////////////*/
    event VaultCreatedAndRegistered(address indexed vault, string vaultName);
    event AdapterAddedToList(IProtocolAdapter indexed adapter, string adapterName);

    /*//////////////////////////////////////////////////////////////
                               错误定义
    //////////////////////////////////////////////////////////////*/
    error AIAgentVaultManager__VaultNotRegistered(address vault);
    error AIAgentVaultManager__InvalidAllocation();
    error AIAgentVaultManager__AdapterNotApproved(IProtocolAdapter adapter);
    error AIAgentVaultManager__AdapterAlreadyApproved(IProtocolAdapter adapter);
    error AIAgentVaultManager__InvalidAdapterIndex(uint256 index);
    error AIAgentVaultManager__AdapterCallFailed();
    error AIAgentVaultManager__BatchLengthMismatch();

    /*//////////////////////////////////////////////////////////////
                               构造函数
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice 构造函数
     */
    constructor() Ownable(msg.sender) {
        // 不再需要 WETH 参数，金库将通过 addVault 手动添加
    }

    /*//////////////////////////////////////////////////////////////
                               外部函数（调用金库相关函数）
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice 添加一个已存在的金库到管理器
     * @param token 金库的代币地址
     * @param vaultAddress 金库合约地址
     */
    function addVault(IERC20 token, address vaultAddress) external onlyOwner {
        if (vaultAddress == address(0)) {
            revert AIAgentVaultManager__VaultNotRegistered(vaultAddress);
        }

        // 检查金库是否已经存在
        if (address(s_vault[token]) != address(0)) {
            revert("Vault already exists for this token");
        }

        s_vault[token] = IVaultShares(vaultAddress);
        emit VaultCreatedAndRegistered(vaultAddress, "Vault");
    }

    /**
     * @notice 更新金库资产分配策略
     * @param token 金库的代币地址
     * @param adapterIndices 适配器索引数组，指定要使用的适配器
     * @param allocationData 新的资产分配数据
     */
    function updateHoldingAllocation(IERC20 token, uint256[] memory adapterIndices, uint256[] memory allocationData)
        external
        onlyOwner
    {
        uint256 indexLength = adapterIndices.length;
        if (allocationData.length != indexLength) {
            revert AIAgentVaultManager__InvalidAllocation();
        }
        address vaultAddress = address(s_vault[token]);
        if (vaultAddress == address(0)) {
            revert AIAgentVaultManager__VaultNotRegistered(vaultAddress);
        }

        // 根据索引构建适配器数组
        IVaultShares.Allocation[] memory allocations = new IVaultShares.Allocation[](indexLength);
        uint256 allAdaptersLength = s_allAdapters.length;
        for (uint256 i = 0; i < indexLength; i++) {
            uint256 adapterIndex = adapterIndices[i];
            if (adapterIndex >= allAdaptersLength) {
                revert AIAgentVaultManager__InvalidAdapterIndex(adapterIndex);
            }
            allocations[i] =
                IVaultShares.Allocation({ adapter: s_allAdapters[adapterIndex], allocation: allocationData[i] });
        }

        // 调用金库的更新函数
        s_vault[token].updateHoldingAllocation(allocations);
    }

    /**
     * @notice 部分更新金库资产分配策略
     * @param token 金库的代币地址
     * @param divestAdapterIndices 需要撤资的适配器索引数组
     * @param divestAmounts 对应的撤资金额数组
     * @param investAdapterIndices 需要投资的适配器索引数组
     * @param investAmounts 需要投资的金额数组
     * @param investAllocations 对应的投资分配比例数组
     */
    function partialUpdateHoldingAllocation(
        IERC20 token,
        uint256[] memory divestAdapterIndices,
        uint256[] memory divestAmounts,
        uint256[] memory investAdapterIndices,
        uint256[] memory investAmounts,
        uint256[] memory investAllocations
    ) external onlyOwner {
        uint256 divestLength = divestAdapterIndices.length;
        uint256 investLength = investAdapterIndices.length;
        // 验证输入参数
        if (divestLength != divestAmounts.length) {
            revert AIAgentVaultManager__InvalidAllocation();
        }

        if (investLength != investAmounts.length) {
            revert AIAgentVaultManager__InvalidAllocation();
        }

        if (investLength != investAllocations.length) {
            revert AIAgentVaultManager__InvalidAllocation();
        }

        address vaultAddress = address(s_vault[token]);
        if (vaultAddress == address(0)) {
            revert AIAgentVaultManager__VaultNotRegistered(vaultAddress);
        }

        // 调用金库的部分更新函数
        s_vault[token].partialUpdateHoldingAllocation(
            divestAdapterIndices, divestAmounts, investAdapterIndices, investAmounts, investAllocations
        );
    }

    /**
     * @notice 撤回金库中所有投资
     * @param token 金库的代币地址
     */
    function withdrawAllInvestments(IERC20 token) external onlyOwner {
        address vaultAddress = address(s_vault[token]);
        if (vaultAddress == address(0)) {
            revert AIAgentVaultManager__VaultNotRegistered(vaultAddress);
        }

        // 调用金库的撤回所有投资函数
        s_vault[token].withdrawAllInvestments();
    }

    /**
     * @notice 设置金库为非活跃状态
     * @param token 金库的代币地址
     */
    function setVaultNotActive(IERC20 token) external onlyOwner {
        address vaultAddress = address(s_vault[token]);
        if (vaultAddress == address(0)) {
            revert AIAgentVaultManager__VaultNotRegistered(vaultAddress);
        }

        // 调用金库的设置非活跃状态函数
        s_vault[token].setNotActive();
    }

    /**
     * @notice 添加协议适配器到全局列表
     * @param adapter 适配器地址
     */
    function addAdapter(IProtocolAdapter adapter) external onlyOwner {
        if (address(adapter) == address(0)) {
            revert AIAgentVaultManager__AdapterNotApproved(adapter);
        }

        // 检查是否已经添加
        if (s_approvedAdapters[adapter]) {
            revert AIAgentVaultManager__AdapterAlreadyApproved(adapter);
        }

        // 先更新状态
        s_approvedAdapters[adapter] = true;
        s_allAdapters.push(adapter);

        emit AdapterAddedToList(adapter, adapter.getName());
    }

    /*//////////////////////////////////////////////////////////////
                               外部函数（调用适配器相关函数）
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice 通过该函数去调用某个适配器内的调整参数函数
     * @param adapterIndex 适配器索引
     * @param value 要发送的ETH数量
     * @param data 调用数据
     */
    function execute(uint256 adapterIndex, uint256 value, bytes calldata data) external onlyOwner {
        // 检查适配器索引是否有效
        if (adapterIndex >= s_allAdapters.length) {
            revert AIAgentVaultManager__InvalidAdapterIndex(adapterIndex);
        }

        // 获取适配器实例
        IProtocolAdapter adapter = s_allAdapters[adapterIndex];

        // 使用低级call执行调用
        (bool success,) = address(adapter).call{ value: value }(data);

        if (!success) {
            revert AIAgentVaultManager__AdapterCallFailed();
        }
    }

    /**
     * @notice 通过多个适配器执行批量调用
     * @param adapterIndices 适配器索引数组，指定要使用的适配器
     * @param values 要发送的ETH数量数组
     * @param data 调用数据数组
     */
    function executeBatch(uint256[] calldata adapterIndices, uint256[] calldata values, bytes[] calldata data)
        external
        onlyOwner
    {
        uint256 adapterLength = adapterIndices.length;
        // 检查数组长度是否一致
        if (adapterLength != values.length || adapterLength != data.length) {
            revert AIAgentVaultManager__BatchLengthMismatch();
        }

        // 初始化返回数据数组
        uint256 allAdapterLength = s_allAdapters.length;

        // 批量执行调用
        for (uint256 i = 0; i < adapterLength; i++) {
            uint256 adapterIndex = adapterIndices[i];
            // 检查适配器索引是否有效
            if (adapterIndex >= allAdapterLength) {
                revert AIAgentVaultManager__InvalidAdapterIndex(adapterIndex);
            }

            // 获取适配器实例
            IProtocolAdapter adapter = s_allAdapters[adapterIndex];
            uint256 value = values[i];
            bytes memory data_i = data[i];

            // 使用低级call执行调用
            (bool success,) = address(adapter).call{ value: value }(data_i);

            if (!success) {
                revert AIAgentVaultManager__AdapterCallFailed();
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                               视图函数
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice 检查适配器是否被批准
     * @param adapter 适配器地址
     * @return 是否被批准
     */
    function isAdapterApproved(IProtocolAdapter adapter) external view returns (bool) {
        return s_approvedAdapters[adapter];
    }

    /**
     * @notice 获取全局适配器列表
     * @return adapters 适配器列表
     */
    function getAllAdapters() external view returns (IProtocolAdapter[] memory adapters) {
        return s_allAdapters;
    }
}
