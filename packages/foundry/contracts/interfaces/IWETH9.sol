// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// WETH9 接口，用于 ETH 和 WETH 之间的转换
interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}
