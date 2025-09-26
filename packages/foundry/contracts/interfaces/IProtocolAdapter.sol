// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IProtocolAdapter
 * @notice 通用协议适配器接口，用于支持多种DeFi协议
 */
interface IProtocolAdapter {
    /**
     * @notice 投资资产到协议中
     * @param asset 要投资的资产
     * @param amount 投资数量
     * @return 实际投资的数量
     */
    function invest(IERC20 asset, uint256 amount) external returns (uint256);

    /**
     * @notice 从协议中撤资
     * @param asset 要撤资的资产
     * @param amount 撤资数量
     * @return 实际撤资的数量
     */
    function divest(IERC20 asset, uint256 amount) external returns (uint256);

    /**
     * @notice 获取在协议中的资产总价值
     * @param asset 资产地址
     * @return 资产总价值
     */
    function getTotalValue(IERC20 asset) external view returns (uint256);

    /**
     * @notice 获取协议适配器的名称
     * @return 协议名称
     */
    function getName() external view returns (string memory);
}
