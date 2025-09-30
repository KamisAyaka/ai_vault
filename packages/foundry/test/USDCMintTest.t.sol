// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../test/mock/MockToken.sol";

contract USDCMintTest is Test {
    MockToken public usdc;
    address public testUser = address(0x123);

    function setUp() public {
        usdc = new MockToken("USD Coin", "USDC");
    }

    function testUSDCBalance() public {
        uint256 amount = 1000 * 10 ** 18;

        console.log("Before mint - User balance:", usdc.balanceOf(testUser));
        console.log(
            "Before mint - Deployer balance:",
            usdc.balanceOf(address(this))
        );

        // 尝试为测试用户 mint USDC
        usdc.mint(testUser, amount);

        console.log("After mint - User balance:", usdc.balanceOf(testUser));
        console.log(
            "After mint - Deployer balance:",
            usdc.balanceOf(address(this))
        );

        assertEq(usdc.balanceOf(testUser), amount);
    }
}
