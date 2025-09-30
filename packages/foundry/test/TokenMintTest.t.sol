// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../test/mock/MockToken.sol";

contract TokenMintTest is Test {
    MockToken public usdc;

    function setUp() public {
        usdc = new MockToken("USD Coin", "USDC");
    }

    function testMint() public {
        address user = address(0x123);
        uint256 amount = 1000 * 10 ** 18;

        console.log("Before mint - User balance:", usdc.balanceOf(user));

        usdc.mint(user, amount);

        console.log("After mint - User balance:", usdc.balanceOf(user));
        console.log("Expected amount:", amount);

        assertEq(usdc.balanceOf(user), amount);
    }
}
