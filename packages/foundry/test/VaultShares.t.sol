// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../contracts/protocol/VaultShares.sol";
import "./mock/MockToken.sol";
import "./mock/MockAdapter.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VaultSharesTest is Test {
    VaultShares public vault;
    MockToken public token;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = address(0x123);

        token = new MockToken("Test Token", "TEST");
        token.transfer(user, 1000 * 10 ** 18);

        IVaultShares.ConstructorData memory constructorData = IVaultShares.ConstructorData({
            asset: IERC20(address(token)),
            Fee: 100, // 1% fee
            vaultName: "Test Vault",
            vaultSymbol: "TVLT"
        });

        vault = new VaultShares(constructorData);
    }

    function testDeposit() public {
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);

        vm.prank(user);
        uint256 shares = vault.deposit(100 * 10 ** 18, user);

        // 由于1%费用，用户实际获得的份额应该是预期份额的99%
        assertGt(shares, 0);
        assertEq(vault.balanceOf(user), shares * 99 / 100); // 用户获得99%的份额
        assertEq(vault.balanceOf(owner), shares * 1 / 100); // 费用收取方获得1%的份额
    }

    function testWithdraw() public {
        // First deposit
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);

        vm.prank(user);
        uint256 shares = vault.deposit(100 * 10 ** 18, user);

        // Check that shares were minted correctly
        // User gets 99% of shares (99 tokens worth) due to 1% fee going to owner
        assertEq(shares, 100 * 10 ** 18);
        assertEq(vault.balanceOf(user), 99 * 10 ** 18);
        assertEq(vault.balanceOf(owner), 1 * 10 ** 18);

        // Then withdraw
        vm.prank(user);
        uint256 assets = vault.withdraw(50 * 10 ** 18, user, user);

        assertEq(assets, 50 * 10 ** 18);
        // User should have 950 tokens now:
        // - Started with 1000 tokens
        // - Deposited 100 tokens (transferred to vault)
        // - Withdrew 50 tokens (transferred back to user)
        // - So user has 950 tokens
        assertEq(token.balanceOf(user), 950 * 10 ** 18);
    }

    function testSetNotActive() public {
        vm.prank(owner);
        vault.setNotActive();

        assertFalse(vault.getIsActive());
    }

    function testUpdateHoldingAllocation() public {
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");

        IVaultShares.Allocation[] memory allocations = new IVaultShares.Allocation[](2);
        allocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter1)),
            allocation: 600 // 60%
         });
        allocations[1] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter2)),
            allocation: 400 // 40%
         });

        vm.prank(owner);
        vault.updateHoldingAllocation(allocations);

        // Deposit some funds to trigger investment
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);

        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // Check that funds were invested
        assertEq(adapter1.getTotalValue(IERC20(address(token))), 60 * 10 ** 18);
        assertEq(adapter2.getTotalValue(IERC20(address(token))), 40 * 10 ** 18);
    }

    function testWithdrawAllInvestments() public {
        MockAdapter adapter = new MockAdapter("Adapter");

        IVaultShares.Allocation[] memory allocations = new IVaultShares.Allocation[](1);
        allocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter)),
            allocation: 1000 // 100%
         });

        vm.prank(owner);
        vault.updateHoldingAllocation(allocations);

        // Deposit some funds to trigger investment
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);

        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // Verify investment
        assertEq(adapter.getTotalValue(IERC20(address(token))), 100 * 10 ** 18);

        // Withdraw all investments
        vm.prank(owner);
        vault.withdrawAllInvestments();

        // Verify divestment
        assertEq(adapter.getTotalValue(IERC20(address(token))), 0);
        assertEq(token.balanceOf(address(vault)), 100 * 10 ** 18);
    }

    function testTotalAssets() public {
        MockAdapter adapter = new MockAdapter("Adapter");

        IVaultShares.Allocation[] memory allocations = new IVaultShares.Allocation[](1);
        allocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter)),
            allocation: 1000 // 100%
         });

        vm.prank(owner);
        vault.updateHoldingAllocation(allocations);

        // Initially no assets
        assertEq(vault.totalAssets(), 0);

        // Deposit some funds
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);

        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // Now we should have assets (200 total)
        // 100 tokens stay in contract (due to mock token behavior)
        // 100 tokens are "invested" in adapter (but also stay in contract due to mock)
        // Total assets = 100 + 100 = 200 tokens
        assertEq(vault.totalAssets(), 200 * 10 ** 18);
    }

    // 新增测试用例：测试存款后提取全部资产
    function testWithdrawAll() public {
        // Deposit
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);

        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // User now has 99 shares (99 tokens worth due to 1% fee)
        assertEq(vault.balanceOf(user), 99 * 10 ** 18);

        // Withdraw all shares
        vm.prank(user);
        uint256 assets = vault.redeem(99 * 10 ** 18, user, user);

        // Should get back 99 tokens
        assertEq(assets, 99 * 10 ** 18);
        assertEq(token.balanceOf(user), 999 * 10 ** 18); // Started with 1000, deposited 100, withdrew 99
        assertEq(vault.balanceOf(user), 0);
    }

    // 新增测试用例：测试金库非活跃状态
    function testDepositWhenNotActive() public {
        // Set vault as not active
        vm.prank(owner);
        vault.setNotActive();

        // Try to deposit - should fail
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);

        vm.prank(user);
        vm.expectRevert(VaultShares.VaultShares__VaultNotActive.selector);
        vault.deposit(100 * 10 ** 18, user);
    }

    // 新增测试用例：测试所有者提取费用份额
    function testOwnerWithdrawFeeShares() public {
        uint256 ownerInitialBalance = token.balanceOf(owner);

        // Deposit
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);

        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // Owner now has 1 share as fee
        assertEq(vault.balanceOf(owner), 1 * 10 ** 18);

        // Owner can withdraw their shares
        vm.prank(owner);
        uint256 assets = vault.redeem(1 * 10 ** 18, owner, owner);

        // Should get back 1 token
        assertEq(assets, 1 * 10 ** 18);
        // Owner should have initial balance + 1 token from redeeming fee shares
        assertEq(token.balanceOf(owner), ownerInitialBalance + 1 * 10 ** 18);
        assertEq(vault.balanceOf(owner), 0);
    }

    // 新增测试用例：测试部分更新投资分配
    function testPartialUpdateHoldingAllocation() public {
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");

        // Initial allocation - only adapter1
        IVaultShares.Allocation[] memory initialAllocations = new IVaultShares.Allocation[](1);
        initialAllocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter1)),
            allocation: 1000 // 100%
         });

        vm.prank(owner);
        vault.updateHoldingAllocation(initialAllocations);

        // Deposit some funds
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);

        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // Check initial investment
        assertEq(adapter1.getTotalValue(IERC20(address(token))), 100 * 10 ** 18);
        assertEq(adapter2.getTotalValue(IERC20(address(token))), 0);

        // Partial update - move 30% from adapter1 to adapter2
        uint256[] memory divestIndices = new uint256[](1);
        divestIndices[0] = 0; // adapter1 index

        uint256[] memory divestAmounts = new uint256[](1);
        divestAmounts[0] = 30 * 10 ** 18; // divest 30 tokens from adapter1

        uint256[] memory investIndices = new uint256[](1);
        investIndices[0] = 0; // adapter2 index (will be added to allocations)

        uint256[] memory investAmounts = new uint256[](1);
        investAmounts[0] = 30 * 10 ** 18; // invest 30 tokens in adapter2

        uint256[] memory investAllocations = new uint256[](1);
        investAllocations[0] = 300; // 30% allocation for adapter2

        // Update allocations to include adapter2
        IVaultShares.Allocation[] memory updatedAllocations = new IVaultShares.Allocation[](2);
        updatedAllocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter1)),
            allocation: 700 // 70%
         });
        updatedAllocations[1] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter2)),
            allocation: 300 // 30%
         });

        // Manually update allocations first (this would normally be done via a separate function)
        vm.prank(owner);
        vault.updateHoldingAllocation(updatedAllocations);

        // Then do partial update
        vm.prank(owner);
        vault.partialUpdateHoldingAllocation(
            divestIndices, divestAmounts, investIndices, investAmounts, investAllocations
        );

        // Check updated investments
        assertEq(adapter1.getTotalValue(IERC20(address(token))), 70 * 10 ** 18);
        assertEq(adapter2.getTotalValue(IERC20(address(token))), 30 * 10 ** 18);
    }
}
