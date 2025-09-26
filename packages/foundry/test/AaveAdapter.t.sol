// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/protocol/investableUniverseAdapters/AaveAdapter.sol";
import "./mock/MockToken.sol";
import "./mock/MockAavePool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AaveAdapterTest is Test {
    AaveAdapter public adapter;
    MockAavePool public mockPool;
    MockToken public token;
    address public owner;
    address public vault;

    event NoLongerActive();

    function setUp() public {
        owner = address(this);
        vault = address(0x123);

        // Deploy mock token
        token = new MockToken("Test Token", "TEST");
        token.mint(vault, 1000 * 10 ** 18);

        // Deploy mock Aave pool
        mockPool = new MockAavePool();

        // Pre-create aToken for the token
        mockPool.createAToken(address(token));
        // Set normalized income to 1e27 (no interest accrued)
        mockPool.setReserveNormalizedIncome(address(token), 1e27);

        // Deploy adapter
        adapter = new AaveAdapter(address(mockPool));

        // Set token vault
        vm.prank(owner);
        adapter.setTokenVault(IERC20(address(token)), vault);
    }

    function testSetTokenVault() public {
        // Test that owner can set token vault
        vm.prank(owner);
        MockToken newToken = new MockToken("New Token", "NEW");
        // Pre-create aToken for new token
        mockPool.createAToken(address(newToken));
        adapter.setTokenVault(IERC20(address(newToken)), address(0x456));

        // Test that non-owner cannot set token vault
        vm.prank(address(0x789));
        vm.expectRevert();
        adapter.setTokenVault(IERC20(address(newToken)), address(0xABC));
    }

    function testInvest() public {
        // Approve adapter to spend vault's tokens
        vm.prank(vault);
        token.approve(address(adapter), 100 * 10 ** 18);

        // Test that vault can invest
        vm.prank(vault);
        uint256 investedAmount = adapter.invest(IERC20(address(token)), 100 * 10 ** 18);

        assertEq(investedAmount, 100 * 10 ** 18);

        // Check that tokens were transferred from vault to adapter
        assertEq(token.balanceOf(vault), 900 * 10 ** 18);
        assertEq(token.balanceOf(address(adapter)), 0); // Adapter should not hold tokens after investing
        assertEq(token.balanceOf(address(mockPool)), 100 * 10 ** 18); // Pool should hold the tokens

        // Check that aTokens were minted to adapter
        MockAToken aToken = MockAToken(mockPool.aTokenAddresses(address(token)));
        assertEq(aToken.balanceOf(address(adapter)), 100 * 10 ** 18);
    }

    function testInvestFromNonVault() public {
        // Test that non-vault cannot invest
        vm.prank(address(0x456));
        vm.expectRevert(AaveAdapter.OnlyVaultCanCallThisFunction.selector);
        adapter.invest(IERC20(address(token)), 100 * 10 ** 18);
    }

    function testDivest() public {
        // First invest
        vm.prank(vault);
        token.approve(address(adapter), 100 * 10 ** 18);

        vm.prank(vault);
        adapter.invest(IERC20(address(token)), 100 * 10 ** 18);

        // Test that vault can divest
        vm.prank(vault);
        uint256 divestedAmount = adapter.divest(IERC20(address(token)), 50 * 10 ** 18);

        assertEq(divestedAmount, 50 * 10 ** 18);

        // Check that tokens were transferred back to vault
        assertEq(token.balanceOf(vault), 950 * 10 ** 18); // Started with 1000, invested 100, divested 50
        assertEq(token.balanceOf(address(adapter)), 0); // Adapter should not hold tokens
        assertEq(token.balanceOf(address(mockPool)), 50 * 10 ** 18); // Pool should hold remaining tokens

        // Check that aTokens were burned from adapter
        MockAToken aToken = MockAToken(mockPool.aTokenAddresses(address(token)));
        assertEq(aToken.balanceOf(address(adapter)), 50 * 10 ** 18); // Should have 50 aTokens left
    }

    function testDivestFromNonVault() public {
        // Test that non-vault cannot divest
        vm.prank(address(0x456));
        vm.expectRevert(AaveAdapter.OnlyVaultCanCallThisFunction.selector);
        adapter.divest(IERC20(address(token)), 100 * 10 ** 18);
    }

    function testGetTotalValue() public {
        // Initially should be 0
        assertEq(adapter.getTotalValue(IERC20(address(token))), 0);

        // After investing
        vm.prank(vault);
        token.approve(address(adapter), 100 * 10 ** 18);

        vm.prank(vault);
        adapter.invest(IERC20(address(token)), 100 * 10 ** 18);

        // Debug information
        MockAToken aToken = MockAToken(mockPool.aTokenAddresses(address(token)));
        uint256 aTokenBalance = aToken.balanceOf(address(adapter));
        console.log("aToken balance of adapter:", aTokenBalance);
        console.log("Adapter address:", address(adapter));
        console.log("aToken address:", address(aToken));

        // Check reserve data
        DataTypes.ReserveData memory reserveData = mockPool.getReserveData(address(token));
        console.log("aToken address from reserve data:", reserveData.aTokenAddress);

        // Check normalized income
        uint256 normalizedIncome = mockPool.getReserveNormalizedIncome(address(token));
        console.log("Normalized income:", normalizedIncome);

        // Should have 100 tokens worth of value
        uint256 totalValue = adapter.getTotalValue(IERC20(address(token)));
        console.log("Total value:", totalValue);
        assertEq(totalValue, 100 * 10 ** 18);
    }

    function testATokenBalance() public {
        // After investing
        vm.prank(vault);
        token.approve(address(adapter), 100 * 10 ** 18);

        vm.prank(vault);
        adapter.invest(IERC20(address(token)), 100 * 10 ** 18);

        // Check aToken balance
        MockAToken aToken = MockAToken(mockPool.aTokenAddresses(address(token)));
        uint256 aTokenBalance = aToken.balanceOf(address(adapter));
        console.log("aToken balance of adapter:", aTokenBalance);

        assertGt(aTokenBalance, 0);
    }

    function testGetName() public view {
        assertEq(adapter.getName(), "Aave");
    }
}
