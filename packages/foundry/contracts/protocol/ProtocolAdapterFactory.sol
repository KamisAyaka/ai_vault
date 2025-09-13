// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";

/**
 * @title ProtocolAdapterFactory
 * @notice 协议适配器工厂，用于创建和管理协议适配器实例
 */
contract ProtocolAdapterFactory is Ownable {
    // 协议名称到实现地址的映射
    mapping(string => address) private s_implementations;
    // 已创建的适配器实例映射
    mapping(address => bool) private s_createdAdapters;

    event AdapterImplementationRegistered(
        string protocolName,
        address implementation
    );
    event AdapterImplementationUnregistered(
        string protocolName,
        address implementation
    );
    event AdapterCreated(string protocolName, address adapter, address creator);

    error ProtocolAdapterFactory__ImplementationAlreadyRegistered(
        string protocolName
    );
    error ProtocolAdapterFactory__InvalidImplementation();
    error ProtocolAdapterFactory__ImplementationNotRegistered(
        string protocolName
    );
    error ProtocolAdapterFactory__AdapterCreationFailed();

    constructor() Ownable(msg.sender) {}

    /**
     * @notice 注册协议适配器实现
     * @param protocolName 协议名称
     * @param implementation 实现地址
     */
    function registerAdapterImplementation(
        string memory protocolName,
        address implementation
    ) external onlyOwner {
        if (implementation == address(0)) {
            revert ProtocolAdapterFactory__InvalidImplementation();
        }

        if (s_implementations[protocolName] != address(0)) {
            revert ProtocolAdapterFactory__ImplementationAlreadyRegistered(
                protocolName
            );
        }

        s_implementations[protocolName] = implementation;
        emit AdapterImplementationRegistered(protocolName, implementation);
    }

    /**
     * @notice 注销协议适配器实现
     * @param protocolName 协议名称
     */
    function unregisterAdapterImplementation(
        string memory protocolName
    ) external onlyOwner {
        address implementation = s_implementations[protocolName];
        if (implementation == address(0)) {
            revert ProtocolAdapterFactory__ImplementationNotRegistered(
                protocolName
            );
        }

        delete s_implementations[protocolName];
        emit AdapterImplementationUnregistered(protocolName, implementation);
    }

    /**
     * @notice 创建协议适配器实例
     * @param protocolName 协议名称
     * @param salt 用于create2的盐值
     * @param initializationData 初始化数据
     * @return adapter 适配器地址
     */
    function createAdapter(
        string memory protocolName,
        bytes32 salt,
        bytes memory initializationData
    ) external returns (address adapter) {
        address implementation = s_implementations[protocolName];
        if (implementation == address(0)) {
            revert ProtocolAdapterFactory__ImplementationNotRegistered(
                protocolName
            );
        }

        // 使用CREATE2创建合约
        assembly {
            adapter := create2(
                0,
                add(implementation, 0x20),
                mload(implementation),
                salt
            )
        }

        if (adapter == address(0)) {
            revert ProtocolAdapterFactory__AdapterCreationFailed();
        }

        // 初始化适配器
        if (initializationData.length > 0) {
            (bool success, ) = adapter.call(initializationData);
            if (!success) {
                revert ProtocolAdapterFactory__AdapterCreationFailed();
            }
        }

        s_createdAdapters[adapter] = true;
        emit AdapterCreated(protocolName, adapter, msg.sender);
    }

    /**
     * @notice 检查适配器是否由本工厂创建
     * @param adapter 适配器地址
     * @return 是否由本工厂创建
     */
    function isCreatedAdapter(address adapter) external view returns (bool) {
        return s_createdAdapters[adapter];
    }

    /**
     * @notice 获取协议实现地址
     * @param protocolName 协议名称
     * @return implementation 实现地址
     */
    function getImplementation(
        string memory protocolName
    ) external view returns (address) {
        return s_implementations[protocolName];
    }
}
