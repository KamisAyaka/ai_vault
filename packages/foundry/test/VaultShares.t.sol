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

        vault = new VaultShares(constructorData); // 基础 VaultShares 不需要 WETH 参数
    }

    function testDeposit() public {
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);

        vm.prank(user);
        uint256 shares = vault.deposit(100 * 10 ** 18, user);

        // 由于1%费用，用户实际获得的份额应该是预期份额的99%
        assertGt(shares, 0);
        // The shares returned is the user shares (99% of total)
        // The owner gets 1% fee shares separately
        uint256 totalShares = vault.previewDeposit(100 * 10 ** 18);
        uint256 expectedFeeShares = (totalShares * 1) / 100; // 1% fee
        uint256 expectedUserShares = totalShares - expectedFeeShares; // 99% for user

        assertEq(vault.balanceOf(user), shares); // User gets the returned shares
        assertEq(vault.balanceOf(owner), expectedFeeShares); // Owner gets fee shares
        assertEq(shares, expectedUserShares); // Returned shares should equal expected user shares
    }

    function testWithdraw() public {
        // First deposit
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);

        vm.prank(user);
        uint256 shares = vault.deposit(100 * 10 ** 18, user);

        // Check that shares were minted correctly
        uint256 totalShares = vault.previewDeposit(100 * 10 ** 18);
        uint256 expectedFeeShares = (totalShares * 1) / 100; // 1% fee
        uint256 expectedUserShares = totalShares - expectedFeeShares; // 99% for user

        assertEq(vault.balanceOf(user), shares); // User gets the returned shares
        assertEq(vault.balanceOf(owner), expectedFeeShares); // Owner gets fee shares
        assertEq(shares, expectedUserShares); // Returned shares should equal expected user shares

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

    // 测试mint函数以提高覆盖率
    function testMint() public {
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);

        vm.prank(user);
        uint256 assets = vault.mint(100 * 10 ** 18, user);

        assertGt(assets, 0);

        // 验证用户获得了正确的份额
        uint256 expectedShares = 100 * 10 ** 18;
        uint256 feeShares = (expectedShares * 1) / 100; // 1% fee
        uint256 userShares = expectedShares - feeShares; // 99% for user

        assertEq(vault.balanceOf(user), userShares);
        assertEq(vault.balanceOf(owner), feeShares);
    }

    // 测试mint函数超过最大限额的情况
    function testMintMoreThanMax() public {
        // 尝试铸造超过最大限额的份额（在没有足够授权的情况下）
        vm.prank(user);
        vm.expectRevert(); // 会抛出ERC20的错误
        vault.mint(10000 * 10 ** 18, user);
    }

    // 测试空的投资分配数组
    function testEmptyAllocations() public {
        IVaultShares.Allocation[] memory emptyAllocations = new IVaultShares.Allocation[](0);

        vm.prank(owner);
        vault.updateHoldingAllocation(emptyAllocations);

        // 存入资产
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);
        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // 验证资产保留在合约中（没有投资）
        assertEq(token.balanceOf(address(vault)), 100 * 10 ** 18);
    }

    // 测试零投资金额的情况
    function testZeroInvestmentAmount() public {
        MockAdapter adapter = new MockAdapter("Zero Investment Adapter");

        // 设置一个分配比例，但资产余额为0
        IVaultShares.Allocation[] memory allocations = new IVaultShares.Allocation[](1);
        allocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter)),
            allocation: 1000 // 100%
         });

        vm.prank(owner);
        vault.updateHoldingAllocation(allocations);

        // 不存入任何资产，直接调用投资函数（通过deposit触发）
        vm.prank(user);
        token.approve(address(vault), 0);
        vm.prank(user);
        vault.deposit(0, user);

        // 验证没有进行任何投资
        assertEq(adapter.getTotalValue(IERC20(address(token))), 0);
    }

    // 测试redeem函数的错误处理路径
    function testRedeemMoreThanMax() public {
        // 存入一些资产
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);
        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // 尝试赎回超过拥有的份额
        vm.prank(user);
        vm.expectRevert(); // 会抛出ERC20的错误
        vault.redeem(200 * 10 ** 18, user, user);
    }

    // 测试withdraw函数的错误处理路径
    function testWithdrawMoreThanMax() public {
        // 存入一些资产
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);
        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // 尝试提取超过可提取的资产
        vm.prank(user);
        vm.expectRevert(); // 会抛出ERC20的错误
        vault.withdraw(200 * 10 ** 18, user, user);
    }

    // 测试_divestFunds函数在空分配数组情况下的行为
    function testDivestWithEmptyAllocations() public {
        // 更新为一个空的分配数组
        IVaultShares.Allocation[] memory emptyAllocations = new IVaultShares.Allocation[](0);
        vm.prank(owner);
        vault.updateHoldingAllocation(emptyAllocations);

        // 存入一些资产
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);
        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // 提取资产应该正常工作，即使没有分配
        vm.prank(user);
        uint256 assets = vault.withdraw(50 * 10 ** 18, user, user);
        assertEq(assets, 50 * 10 ** 18);
    }

    // 测试零撤资金额的情况
    function testZeroDivestmentAmount() public {
        MockAdapter adapter = new MockAdapter("Zero Divestment Adapter");

        // 设置分配
        IVaultShares.Allocation[] memory allocations = new IVaultShares.Allocation[](1);
        allocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter)),
            allocation: 1000 // 100%
         });

        vm.prank(owner);
        vault.updateHoldingAllocation(allocations);

        // 存入资产
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);
        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // 提取0资产应该正常工作
        vm.prank(user);
        uint256 assets = vault.withdraw(0, user, user);
        assertEq(assets, 0);
    }

    // ========== 额外的边界条件和错误处理测试 ==========

    function testDepositWithZeroAmount() public {
        vm.prank(user);
        token.approve(address(vault), 0);

        vm.prank(user);
        uint256 shares = vault.deposit(0, user);
        assertEq(shares, 0);
        assertEq(vault.balanceOf(user), 0);
    }

    function testDepositWithMaxAmount() public {
        uint256 maxAmount = 1000 * 10 ** 18; // Use all available tokens instead of type(uint256).max
        vm.prank(user);
        token.approve(address(vault), maxAmount);

        vm.prank(user);
        uint256 shares = vault.deposit(maxAmount, user);
        assertGt(shares, 0);
    }

    function testMintWithZeroAmount() public {
        vm.prank(user);
        token.approve(address(vault), 0);

        vm.prank(user);
        uint256 assets = vault.mint(0, user);
        assertEq(assets, 0);
        assertEq(vault.balanceOf(user), 0);
    }

    function testMintWithMaxAmount() public {
        uint256 maxAmount = 1000 * 10 ** 18; // Use all available tokens instead of type(uint256).max
        vm.prank(user);
        token.approve(address(vault), maxAmount);

        vm.prank(user);
        uint256 assets = vault.mint(maxAmount, user);
        assertGt(assets, 0);
    }

    function testRedeemWithZeroAmount() public {
        // 先存入一些资产
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);
        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        vm.prank(user);
        uint256 assets = vault.redeem(0, user, user);
        assertEq(assets, 0);
    }

    function testWithdrawWithZeroAmount() public {
        // 先存入一些资产
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);
        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        vm.prank(user);
        uint256 assets = vault.withdraw(0, user, user);
        assertEq(assets, 0);
    }

    function testWithdrawAllWithZeroBalance() public {
        // 在没有存款的情况下尝试提取所有资产
        vm.prank(user);
        uint256 assets = vault.withdraw(vault.balanceOf(user), user, user);
        assertEq(assets, 0);
    }

    function testRedeemAllWithZeroBalance() public {
        // 在没有存款的情况下尝试赎回所有份额
        vm.prank(user);
        uint256 assets = vault.redeem(vault.balanceOf(user), user, user);
        assertEq(assets, 0);
    }

    function testUpdateHoldingAllocationWithZeroAllocation() public {
        MockAdapter adapter = new MockAdapter("Test Adapter");

        // 设置分配为0
        IVaultShares.Allocation[] memory allocations = new IVaultShares.Allocation[](1);
        allocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter)),
            allocation: 0 // 0% allocation
         });

        vm.prank(owner);
        vault.updateHoldingAllocation(allocations);

        // 存入资产
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);
        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // 提取资产应该正常工作
        vm.prank(user);
        uint256 assets = vault.withdraw(50 * 10 ** 18, user, user);
        assertEq(assets, 50 * 10 ** 18);
    }

    function testPartialUpdateHoldingAllocationWithZeroAmounts() public {
        MockAdapter adapter = new MockAdapter("Test Adapter");

        // 设置初始分配
        IVaultShares.Allocation[] memory initialAllocations = new IVaultShares.Allocation[](1);
        initialAllocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter)),
            allocation: 1000 // 100%
         });

        vm.prank(owner);
        vault.updateHoldingAllocation(initialAllocations);

        // 存入资产
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);
        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // 部分更新分配，使用零金额
        uint256[] memory divestAdapterIndices = new uint256[](1);
        divestAdapterIndices[0] = 0;

        uint256[] memory divestAmounts = new uint256[](1);
        divestAmounts[0] = 0; // 零撤资金额

        uint256[] memory investAdapterIndices = new uint256[](1);
        investAdapterIndices[0] = 0;

        uint256[] memory investAmounts = new uint256[](1);
        investAmounts[0] = 0; // 零投资金额

        uint256[] memory investAllocations = new uint256[](1);
        investAllocations[0] = 1000;

        vm.prank(owner);
        vault.partialUpdateHoldingAllocation(
            divestAdapterIndices, divestAmounts, investAdapterIndices, investAmounts, investAllocations
        );

        // 提取资产应该正常工作
        uint256 userBalanceBefore = token.balanceOf(user);
        vm.prank(user);
        uint256 sharesBurned = vault.withdraw(50 * 10 ** 18, user, user);
        uint256 userBalanceAfter = token.balanceOf(user);

        // 检查用户实际收到了50个代币
        assertEq(userBalanceAfter - userBalanceBefore, 50 * 10 ** 18);
        // 检查返回值是燃烧的份额数量，不是资产数量
        assertGt(sharesBurned, 0);
    }

    function testWithdrawAllInvestmentsWithEmptyAllocations() public {
        // 设置空分配
        IVaultShares.Allocation[] memory emptyAllocations = new IVaultShares.Allocation[](0);
        vm.prank(owner);
        vault.updateHoldingAllocation(emptyAllocations);

        // 存入资产
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);
        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // 撤回所有投资应该正常工作
        vm.prank(owner);
        vault.withdrawAllInvestments();
    }

    function testSetNotActiveWhenAlreadyInactive() public {
        // 设置为非活跃状态
        vm.prank(owner);
        vault.setNotActive();

        // 再次设置为非活跃状态应该失败，因为已经有isActive修饰符
        vm.prank(owner);
        vm.expectRevert(VaultShares.VaultShares__VaultNotActive.selector);
        vault.setNotActive();
    }

    function testDepositWhenInactive() public {
        // 设置为非活跃状态
        vm.prank(owner);
        vault.setNotActive();

        // 尝试存入资产应该失败
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);
        vm.prank(user);
        vm.expectRevert();
        vault.deposit(100 * 10 ** 18, user);
    }

    function testMintWhenInactive() public {
        // 设置为非活跃状态
        vm.prank(owner);
        vault.setNotActive();

        // 尝试铸造份额应该失败
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);
        vm.prank(user);
        vm.expectRevert();
        vault.mint(100 * 10 ** 18, user);
    }

    function testWithdrawWhenInactive() public {
        // 先存入一些资产
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);
        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // 设置为非活跃状态
        vm.prank(owner);
        vault.setNotActive();

        // 提取资产应该正常工作（非活跃状态不影响提取）
        vm.prank(user);
        uint256 assets = vault.withdraw(50 * 10 ** 18, user, user);
        assertEq(assets, 50 * 10 ** 18);
    }

    function testRedeemWhenInactive() public {
        // 先存入一些资产
        vm.prank(user);
        token.approve(address(vault), 100 * 10 ** 18);
        vm.prank(user);
        vault.deposit(100 * 10 ** 18, user);

        // 设置为非活跃状态
        vm.prank(owner);
        vault.setNotActive();

        // 赎回份额应该正常工作（非活跃状态不影响赎回）
        vm.prank(user);
        uint256 assets = vault.redeem(50 * 10 ** 18, user, user);
        assertEq(assets, 50 * 10 ** 18);
    }

    function testTotalAssetsWithZeroBalance() public view {
        // 在没有资产的情况下获取总资产
        uint256 totalAssets = vault.totalAssets();
        assertEq(totalAssets, 0);
    }

    function testConvertToSharesWithZeroAmount() public view {
        uint256 shares = vault.convertToShares(0);
        assertEq(shares, 0);
    }

    function testConvertToAssetsWithZeroAmount() public view {
        uint256 assets = vault.convertToAssets(0);
        assertEq(assets, 0);
    }

    function testPreviewDepositWithZeroAmount() public view {
        uint256 shares = vault.previewDeposit(0);
        assertEq(shares, 0);
    }

    function testPreviewMintWithZeroAmount() public view {
        uint256 assets = vault.previewMint(0);
        assertEq(assets, 0);
    }

    function testPreviewWithdrawWithZeroAmount() public view {
        uint256 shares = vault.previewWithdraw(0);
        assertEq(shares, 0);
    }

    function testPreviewRedeemWithZeroAmount() public view {
        uint256 assets = vault.previewRedeem(0);
        assertEq(assets, 0);
    }

    function testMaxDeposit() public view {
        uint256 maxDeposit = vault.maxDeposit(user);
        assertEq(maxDeposit, type(uint256).max);
    }

    function testMaxMint() public view {
        uint256 maxMint = vault.maxMint(user);
        assertEq(maxMint, type(uint256).max);
    }

    function testMaxWithdraw() public view {
        uint256 maxWithdraw = vault.maxWithdraw(user);
        assertEq(maxWithdraw, 0); // 用户没有存款
    }

    function testMaxRedeem() public view {
        uint256 maxRedeem = vault.maxRedeem(user);
        assertEq(maxRedeem, 0); // 用户没有份额
    }
}
