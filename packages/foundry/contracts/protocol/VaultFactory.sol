// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVaultShares} from "../interfaces/IVaultShares.sol";
import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";
import {VaultImplementation} from "./VaultImplementation.sol";

/**
 * @title VaultFactory
 * @dev 使用最小代理模式创建金库合约的工厂
 * @dev 基于OpenZeppelin的Clones库实现，大幅降低部署gas成本
 */
contract VaultFactory is Ownable {
    /*//////////////////////////////////////////////////////////////
                            状态变量
    //////////////////////////////////////////////////////////////*/

    // 金库实现合约地址
    address public immutable vaultImplementation;

    // 金库管理者合约地址
    address public immutable vaultManager;

    // 已创建的金库映射：代币地址 => 金库地址
    mapping(IERC20 => address) public vaults;

    /*//////////////////////////////////////////////////////////////
                                事件
    //////////////////////////////////////////////////////////////*/

    event VaultCreated(
        address indexed vault,
        IERC20 indexed asset,
        address indexed creator,
        string vaultName,
        string vaultSymbol,
        uint256 fee
    );

    /*//////////////////////////////////////////////////////////////
                                错误定义
    //////////////////////////////////////////////////////////////*/

    error VaultFactory__VaultAlreadyExists(IERC20 asset);
    error VaultFactory__InvalidImplementation();
    error VaultFactory__InvalidFee(uint256 fee);
    error VaultFactory__InvalidVaultName();
    error VaultFactory__InvalidVaultSymbol();

    /*//////////////////////////////////////////////////////////////
                                构造函数
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 构造函数
     * @param _vaultImplementation 标准金库实现合约地址
     * @param _vaultManager 金库管理者合约地址
     */
    constructor(
        address _vaultImplementation,
        address _vaultManager
    ) Ownable(msg.sender) {
        if (_vaultImplementation == address(0)) {
            revert VaultFactory__InvalidImplementation();
        }

        if (_vaultManager == address(0)) {
            revert VaultFactory__InvalidImplementation();
        }

        vaultImplementation = _vaultImplementation;
        vaultManager = _vaultManager;
    }

    /*//////////////////////////////////////////////////////////////
                                外部函数
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 创建新的ERC20代币金库
     * @param asset 金库支持的ERC20代币地址
     * @param vaultName 金库名称
     * @param vaultSymbol 金库代币符号
     * @param fee 管理费率（基点，10000 = 100%）
     * @return vault 新创建的金库地址
     */
    function createVault(
        IERC20 asset,
        string calldata vaultName,
        string calldata vaultSymbol,
        uint256 fee
    ) external onlyOwner returns (address vault) {
        // 验证输入参数
        if (address(asset) == address(0)) {
            revert VaultFactory__InvalidImplementation();
        }

        if (bytes(vaultName).length == 0) {
            revert VaultFactory__InvalidVaultName();
        }

        if (bytes(vaultSymbol).length == 0) {
            revert VaultFactory__InvalidVaultSymbol();
        }

        if (fee > 10000) {
            // 最大100%费率
            revert VaultFactory__InvalidFee(fee);
        }

        // 检查是否已存在该代币的金库
        if (vaults[asset] != address(0)) {
            revert VaultFactory__VaultAlreadyExists(asset);
        }

        // 使用最小代理模式创建金库
        vault = Clones.clone(vaultImplementation);

        // 初始化金库
        IVaultShares.ConstructorData memory constructorData = IVaultShares
            .ConstructorData({
                asset: asset,
                Fee: fee,
                vaultName: vaultName,
                vaultSymbol: vaultSymbol
            });

        // 调用初始化函数，直接设置vaultManager为owner
        VaultImplementation(vault).initialize(constructorData, vaultManager);

        // 记录金库信息
        vaults[asset] = vault;

        emit VaultCreated(
            vault,
            asset,
            msg.sender,
            vaultName,
            vaultSymbol,
            fee
        );
    }

    /**
     * @notice 批量创建金库
     * @param assets 代币地址数组
     * @param vaultNames 金库名称数组
     * @param vaultSymbols 金库代币符号数组
     * @param fees 管理费率数组
     * @return vaults_ 新创建的金库地址数组
     */
    function createVaultsBatch(
        IERC20[] calldata assets,
        string[] calldata vaultNames,
        string[] calldata vaultSymbols,
        uint256[] calldata fees
    ) external onlyOwner returns (address[] memory vaults_) {
        uint256 length = assets.length;

        if (
            length != vaultNames.length ||
            length != vaultSymbols.length ||
            length != fees.length
        ) {
            revert VaultFactory__InvalidImplementation();
        }

        vaults_ = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            // 缓存数组元素以减少SLOAD操作
            IERC20 asset = assets[i];
            string calldata vaultName = vaultNames[i];
            string calldata vaultSymbol = vaultSymbols[i];
            uint256 fee = fees[i];

            // 验证输入参数
            if (address(asset) == address(0)) {
                revert VaultFactory__InvalidImplementation();
            }

            if (bytes(vaultName).length == 0) {
                revert VaultFactory__InvalidVaultName();
            }

            if (bytes(vaultSymbol).length == 0) {
                revert VaultFactory__InvalidVaultSymbol();
            }

            if (fee > 10000) {
                // 最大100%费率
                revert VaultFactory__InvalidFee(fee);
            }

            // 检查是否已存在该代币的金库
            if (vaults[asset] != address(0)) {
                revert VaultFactory__VaultAlreadyExists(asset);
            }

            // 使用最小代理模式创建金库
            address vault = Clones.clone(vaultImplementation);

            // 初始化金库
            IVaultShares.ConstructorData memory constructorData = IVaultShares
                .ConstructorData({
                    asset: asset,
                    Fee: fee,
                    vaultName: vaultName,
                    vaultSymbol: vaultSymbol
                });

            // 调用初始化函数，直接设置vaultManager为owner
            VaultImplementation(vault).initialize(
                constructorData,
                vaultManager
            );

            // 记录金库信息
            vaults[asset] = vault;

            // 发出金库创建事件
            emit VaultCreated(
                vault,
                asset,
                msg.sender,
                vaultName,
                vaultSymbol,
                fee
            );

            vaults_[i] = vault;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                视图函数
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 获取指定代币的金库地址
     * @param asset 代币地址
     * @return 金库地址
     */
    function getVault(IERC20 asset) external view returns (address) {
        return vaults[asset];
    }

    /**
     * @notice 检查指定代币是否已有金库
     * @param asset 代币地址
     * @return 是否已有金库
     */
    function hasVault(IERC20 asset) external view returns (bool) {
        return vaults[asset] != address(0);
    }
}
