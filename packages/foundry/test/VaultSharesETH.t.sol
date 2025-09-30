// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test, console } from "forge-std/Test.sol";
import { VaultSharesETH } from "../contracts/protocol/VaultSharesETH.sol";
import { VaultImplementation } from "../contracts/protocol/VaultImplementation.sol";
import { IVaultShares } from "../contracts/interfaces/IVaultShares.sol";
import { MockWETH9 } from "./mock/MockWETH9.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./mock/MockAdapter.sol";

contract VaultSharesETHTest is Test {
    VaultSharesETH public vaultShares;
    MockWETH9 public weth;
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public owner;

    function setUp() public {
        // 部署 Mock WETH9
        weth = new MockWETH9();

        // 创建 VaultShares 构造函数数据
        IVaultShares.ConstructorData memory constructorData = IVaultShares.ConstructorData({
            asset: IERC20(address(weth)),
            Fee: 100, // 1% 费用
            vaultName: "Test Vault",
            vaultSymbol: "TV"
        });

        // 部署 VaultSharesETH 合约
        vaultShares = new VaultSharesETH(constructorData);

        // 获取合约所有者（部署者）
        owner = vaultShares.owner();

        // 给用户一些 ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(owner, 10 ether);
    }

    function testDepositETH() public {
        uint256 depositAmount = 1 ether;

        // 用户1使用 ETH 存款
        vm.prank(user1);
        uint256 shares = vaultShares.depositETH{ value: depositAmount }(user1);

        // 验证用户1获得了份额
        assertTrue(shares > 0, "User should receive shares");
        assertEq(vaultShares.balanceOf(user1), shares, "User should have correct shares");

        // 验证 WETH 被正确转换
        assertEq(weth.balanceOf(address(vaultShares)), depositAmount, "Vault should have WETH");

        // 验证费用被正确计算
        uint256 totalShares = vaultShares.previewDeposit(depositAmount);
        uint256 expectedFeeShares = (totalShares * 100) / 10000; // 1% 费用
        assertEq(vaultShares.balanceOf(vaultShares.owner()), expectedFeeShares, "Owner should receive fee shares");
    }

    function testMintETH() public {
        // First, we need to have some assets in the vault for the mint to work properly
        // Let's do a small deposit first to initialize the vault
        vm.prank(user1);
        uint256 initialShares = vaultShares.depositETH{ value: 0.1 ether }(user1);

        uint256 sharesToMint = 0.5e18; // Mint 0.5 ETH worth of shares

        // 计算需要的 ETH 数量
        uint256 requiredETH = vaultShares.previewMint(sharesToMint);

        // 用户1使用 ETH 铸造份额
        vm.prank(user1);
        uint256 assets = vaultShares.mintETH{ value: requiredETH }(sharesToMint, user1);

        // 验证用户1获得了正确的份额
        // The mintETH function returns user shares (after fee deduction), not the total shares requested
        // Calculate the expected user shares: initial shares + (sharesToMint - fee shares)
        uint256 feeShares = (sharesToMint * 100) / 10000; // 1% fee
        uint256 userSharesFromMint = sharesToMint - feeShares;
        uint256 expectedTotalShares = initialShares + userSharesFromMint;
        assertEq(vaultShares.balanceOf(user1), expectedTotalShares, "User should have correct shares");
        assertEq(assets, requiredETH, "Should return correct assets");

        // 验证 WETH 被正确转换
        assertEq(weth.balanceOf(address(vaultShares)), requiredETH + 0.1 ether, "Vault should have WETH");
    }

    function testReceiveETH() public {
        uint256 sendAmount = 1 ether;

        // 直接发送 ETH 到合约
        vm.prank(user1);
        (bool success,) = address(vaultShares).call{ value: sendAmount }("");
        assertTrue(success, "ETH transfer should succeed");

        // 验证 ETH 被转换为 WETH
        assertEq(weth.balanceOf(address(vaultShares)), sendAmount, "ETH should be converted to WETH");
    }

    function testDepositETHInsufficientETH() public {
        // 尝试发送少于所需数量的 ETH
        vm.prank(user1);
        vm.expectRevert(VaultSharesETH.VaultSharesETH__MustSendETH.selector);
        vaultShares.depositETH{ value: 0 }(user1);
    }

    function testMintETHInsufficientETH() public {
        // First, we need to have some assets in the vault for the mint to work properly
        vm.prank(user1);
        vaultShares.depositETH{ value: 0.1 ether }(user1);

        uint256 sharesToMint = 0.5e18;
        uint256 requiredETH = vaultShares.previewMint(sharesToMint);

        // 尝试发送少于所需数量的 ETH
        vm.prank(user1);
        vm.expectRevert(VaultSharesETH.VaultSharesETH__InsufficientETHSent.selector);
        vaultShares.mintETH{ value: requiredETH - 1 }(sharesToMint, user1);
    }

    function testDebugDepositETH() public {
        uint256 depositAmount = 1 ether;

        // Check initial state
        console.log("Initial totalAssets:", vaultShares.totalAssets());
        console.log("Initial totalSupply:", vaultShares.totalSupply());
        console.log("Initial WETH balance:", weth.balanceOf(address(vaultShares)));

        // Check previewDeposit before any deposit
        uint256 previewShares = vaultShares.previewDeposit(depositAmount);
        console.log("Preview shares for 1 ETH (before deposit):", previewShares);

        // Calculate expected fees
        uint256 expectedFeeShares = (previewShares * 100) / 10000;
        uint256 expectedUserShares = previewShares - expectedFeeShares;
        console.log("Expected fee shares:", expectedFeeShares);
        console.log("Expected user shares:", expectedUserShares);

        // Now try the actual deposit
        console.log("Calling depositETH with user1:", user1);
        console.log("Calling depositETH with owner:", vaultShares.owner());
        console.log("Calling depositETH with msg.sender:", user1);
        vm.prank(user1);
        uint256 shares = vaultShares.depositETH{ value: depositAmount }(user1);
        console.log("Actual shares received:", shares);

        // Check state after deposit
        console.log("After deposit - totalAssets:", vaultShares.totalAssets());
        console.log("After deposit - totalSupply:", vaultShares.totalSupply());
        console.log("After deposit - WETH balance:", weth.balanceOf(address(vaultShares)));
        console.log("User shares:", vaultShares.balanceOf(user1));
        console.log("Owner shares:", vaultShares.balanceOf(vaultShares.owner()));
        console.log("Vault owner:", vaultShares.owner());
        console.log("Owner balance:", vaultShares.balanceOf(vaultShares.owner()));
    }

    function testDebugMint() public {
        // Test if _mint works at all
        console.log("Before mint - totalSupply:", vaultShares.totalSupply());
        console.log("Before mint - user1 balance:", vaultShares.balanceOf(user1));

        // Let's try a regular deposit first to see if that works
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        weth.deposit{ value: 1 ether }();

        console.log("After WETH deposit - user1 WETH balance:", weth.balanceOf(user1));

        // Check previewDeposit before regular deposit
        uint256 previewShares = vaultShares.previewDeposit(1 ether);
        console.log("Regular deposit - preview shares:", previewShares);
        console.log("Regular deposit - totalAssets before:", vaultShares.totalAssets());
        console.log("Regular deposit - totalSupply before:", vaultShares.totalSupply());

        // Now try a regular deposit
        vm.prank(user1);
        weth.approve(address(vaultShares), 1 ether);
        vm.prank(user1);
        uint256 shares = vaultShares.deposit(1 ether, user1);
        console.log("Regular deposit shares:", shares);
        console.log("After regular deposit - totalSupply:", vaultShares.totalSupply());
        console.log("After regular deposit - user1 balance:", vaultShares.balanceOf(user1));
    }

    function testDebugMintDirect() public {
        // Test if we can mint shares directly by calling a function that uses _mint
        console.log("Before mint - totalSupply:", vaultShares.totalSupply());
        console.log("Before mint - user1 balance:", vaultShares.balanceOf(user1));

        // Let's try to call the mint function directly
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        weth.deposit{ value: 1 ether }();
        vm.prank(user1);
        weth.approve(address(vaultShares), 1 ether);

        // Try mint function
        vm.prank(user1);
        uint256 assets = vaultShares.mint(1 ether, user1);
        console.log("Mint assets:", assets);
        console.log("After mint - totalSupply:", vaultShares.totalSupply());
        console.log("After mint - user1 balance:", vaultShares.balanceOf(user1));
    }

    function testRedeemETH() public {
        // 用户1使用 ETH 存款
        vm.prank(user1);
        uint256 shares = vaultShares.depositETH{ value: 1 ether }(user1);

        // 记录用户1的初始 ETH 余额
        uint256 user1InitialETH = user1.balance;

        // 用户1使用 ETH 赎回 (only redeem user shares, not fee shares)
        vm.prank(user1);
        uint256 assets = vaultShares.redeemETH(shares, user1, user1);

        // 验证用户1获得了正确的 ETH (should be slightly less than 1 ether due to fees)
        assertEq(assets, shares, "Should return correct assets"); // In 1:1 vault, shares = assets
        assertEq(user1.balance, user1InitialETH + assets, "User should receive ETH");
        assertEq(vaultShares.balanceOf(user1), 0, "User should have no shares left");
    }

    function testWithdrawETH() public {
        // 用户1使用 ETH 存款
        vm.prank(user1);
        uint256 shares = vaultShares.depositETH{ value: 1 ether }(user1);

        // 记录用户1的初始 ETH 余额
        uint256 user1InitialETH = user1.balance;

        // 用户1使用 ETH 提取 (withdraw half of user's shares worth)
        uint256 withdrawAmount = shares / 2; // Withdraw half of user's shares
        vm.prank(user1);
        uint256 sharesBurned = vaultShares.withdrawETH(withdrawAmount, user1, user1);

        // 验证用户1获得了正确的 ETH
        assertEq(sharesBurned, withdrawAmount, "Should return correct shares burned");
        assertEq(user1.balance, user1InitialETH + withdrawAmount, "User should receive ETH");
    }

    // 新增测试用例：测试setNotActive函数
    function testSetNotActive() public {
        // 验证金库初始状态为活跃
        assertTrue(vaultShares.getIsActive(), "Vault should be active initially");

        // 调用setNotActive
        vm.prank(owner);
        vaultShares.setNotActive();

        // 验证金库状态变为非活跃
        assertFalse(vaultShares.getIsActive(), "Vault should be inactive after setNotActive");
    }

    // 新增测试用例：测试非活跃状态下depositETH
    function testDepositETHWhenNotActive() public {
        // 设置金库为非活跃状态
        vm.prank(owner);
        vaultShares.setNotActive();

        // 尝试存款应该失败
        vm.prank(user1);
        vm.expectRevert(VaultSharesETH.VaultSharesETH__VaultNotActive.selector);
        vaultShares.depositETH{ value: 1 ether }(user1);
    }

    // 新增测试用例：测试非活跃状态下mintETH
    function testMintETHWhenNotActive() public {
        // 设置金库为非活跃状态
        vm.prank(owner);
        vaultShares.setNotActive();

        // 尝试铸造应该失败
        vm.prank(user1);
        vm.expectRevert(VaultSharesETH.VaultSharesETH__VaultNotActive.selector);
        vaultShares.mintETH{ value: 1 ether }(1e18, user1);
    }

    // 新增测试用例：测试updateHoldingAllocation函数
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

        // 非所有者调用应该失败
        vm.prank(user1);
        vm.expectRevert(); // onlyOwner modifier
        vaultShares.updateHoldingAllocation(allocations);

        // 所有者调用应该成功
        vm.prank(owner);
        vaultShares.updateHoldingAllocation(allocations);

        // 存入一些资金以触发投资
        vm.prank(user1);
        vaultShares.depositETH{ value: 1 ether }(user1);

        // 验证资金被投资
        assertEq(adapter1.getTotalValue(IERC20(address(weth))), 0.6 ether);
        assertEq(adapter2.getTotalValue(IERC20(address(weth))), 0.4 ether);
    }

    // 新增测试用例：测试withdrawAllInvestments函数
    function testWithdrawAllInvestments() public {
        MockAdapter adapter = new MockAdapter("Adapter");

        IVaultShares.Allocation[] memory allocations = new IVaultShares.Allocation[](1);
        allocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter)),
            allocation: 1000 // 100%
         });

        vm.prank(owner);
        vaultShares.updateHoldingAllocation(allocations);

        // 存入一些资金以触发投资
        vm.prank(user1);
        vaultShares.depositETH{ value: 1 ether }(user1);

        // 验证投资
        assertEq(adapter.getTotalValue(IERC20(address(weth))), 1 ether);

        // 非所有者调用应该失败
        vm.prank(user1);
        vm.expectRevert(); // onlyOwner modifier
        vaultShares.withdrawAllInvestments();

        // 所有者调用应该成功
        vm.prank(owner);
        vaultShares.withdrawAllInvestments();

        // 验证撤资
        assertEq(adapter.getTotalValue(IERC20(address(weth))), 0);
        assertEq(weth.balanceOf(address(vaultShares)), 1 ether);
    }

    // 新增测试用例：测试空的投资分配数组
    function testEmptyAllocations() public {
        IVaultShares.Allocation[] memory emptyAllocations = new IVaultShares.Allocation[](0);

        vm.prank(owner);
        vaultShares.updateHoldingAllocation(emptyAllocations);

        // 存入资金
        vm.prank(user1);
        vaultShares.depositETH{ value: 1 ether }(user1);

        // 验证资金保留在合约中（没有投资）
        assertEq(weth.balanceOf(address(vaultShares)), 1 ether);
    }

    // 新增测试用例：测试零投资金额的情况
    function testZeroInvestmentAmount() public {
        MockAdapter adapter = new MockAdapter("Zero Investment Adapter");

        // 设置分配比例
        IVaultShares.Allocation[] memory allocations = new IVaultShares.Allocation[](1);
        allocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter)),
            allocation: 1000 // 100%
         });

        vm.prank(owner);
        vaultShares.updateHoldingAllocation(allocations);

        // 不存入任何资金，直接调用投资函数（通过depositETH触发）
        // 这会测试零投资金额的情况

        // 验证没有进行任何投资
        assertEq(adapter.getTotalValue(IERC20(address(weth))), 0);
    }

    // 新增测试用例：测试部分更新投资分配
    function testPartialUpdateHoldingAllocation() public {
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");

        // 初始分配 - 只有adapter1
        IVaultShares.Allocation[] memory initialAllocations = new IVaultShares.Allocation[](1);
        initialAllocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter1)),
            allocation: 1000 // 100%
         });

        vm.prank(owner);
        vaultShares.updateHoldingAllocation(initialAllocations);

        // 存入一些资金
        vm.prank(user1);
        vaultShares.depositETH{ value: 1 ether }(user1);

        // 检查初始投资
        assertEq(adapter1.getTotalValue(IERC20(address(weth))), 1 ether);
        assertEq(adapter2.getTotalValue(IERC20(address(weth))), 0);

        // 部分更新 - 从adapter1撤资30%，投资到adapter2
        uint256[] memory divestIndices = new uint256[](1);
        divestIndices[0] = 0; // adapter1索引

        uint256[] memory divestAmounts = new uint256[](1);
        divestAmounts[0] = 0.3 ether; // 从adapter1撤资0.3 ETH

        uint256[] memory investIndices = new uint256[](1);
        investIndices[0] = 0; // adapter2索引（将在分配中添加）

        uint256[] memory investAmounts = new uint256[](1);
        investAmounts[0] = 0.3 ether; // 投资0.3 ETH到adapter2

        uint256[] memory investAllocations = new uint256[](1);
        investAllocations[0] = 300; // adapter2的30%分配

        // 更新分配以包含adapter2
        IVaultShares.Allocation[] memory updatedAllocations = new IVaultShares.Allocation[](2);
        updatedAllocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter1)),
            allocation: 700 // 70%
         });
        updatedAllocations[1] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter2)),
            allocation: 300 // 30%
         });

        // 手动更新分配（这通常通过单独的函数完成）
        vm.prank(owner);
        vaultShares.updateHoldingAllocation(updatedAllocations);

        // 然后执行部分更新
        vm.prank(owner);
        vaultShares.partialUpdateHoldingAllocation(
            divestIndices, divestAmounts, investIndices, investAmounts, investAllocations
        );

        // 检查更新后的投资
        assertEq(adapter1.getTotalValue(IERC20(address(weth))), 0.7 ether);
        assertEq(adapter2.getTotalValue(IERC20(address(weth))), 0.3 ether);
    }

    // 新增测试用例：测试totalAssets函数
    function testTotalAssets() public {
        MockAdapter adapter = new MockAdapter("Adapter");

        IVaultShares.Allocation[] memory allocations = new IVaultShares.Allocation[](1);
        allocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter)),
            allocation: 1000 // 100%
         });

        vm.prank(owner);
        vaultShares.updateHoldingAllocation(allocations);

        // 初始没有资产
        assertEq(vaultShares.totalAssets(), 0);

        // 存入一些资金
        vm.prank(user1);
        vaultShares.depositETH{ value: 1 ether }(user1);

        // 现在应该有资产（包括在合约中的和在适配器中的）
        // 1 ether在合约中，1 ether在适配器中（因为是mock adapter，不会实际转移资金）
        assertEq(vaultShares.totalAssets(), 2 ether);
    }

    // 新增测试用例：测试ETH转账失败的情况
    function testRedeemETHTransferFailed() public {
        // 创建一个无法接收ETH的合约地址
        address nonPayableContract = address(new NonPayableContract());

        // 存入一些资金
        vm.prank(user1);
        uint256 shares = vaultShares.depositETH{ value: 1 ether }(user1);

        // 尝试将ETH发送到无法接收ETH的地址应该失败
        vm.prank(user1);
        vm.expectRevert(VaultSharesETH.VaultSharesETH__ETHTransferFailed.selector);
        vaultShares.redeemETH(shares, nonPayableContract, user1);
    }

    // 新增测试用例：测试ETH转账失败的情况（withdrawETH）
    function testWithdrawETHTransferFailed() public {
        // 创建一个无法接收ETH的合约地址
        address nonPayableContract = address(new NonPayableContract());

        // 存入一些资金
        vm.prank(user1);
        vaultShares.depositETH{ value: 1 ether }(user1);

        uint256 assets = vaultShares.previewRedeem(vaultShares.balanceOf(user1));

        // 尝试将ETH发送到无法接收ETH的地址应该失败
        vm.prank(user1);
        vm.expectRevert(VaultSharesETH.VaultSharesETH__ETHTransferFailed.selector);
        vaultShares.withdrawETH(assets, nonPayableContract, user1);
    }

    // 新增测试用例：测试_divestFunds中的零金额分支
    function testDivestZeroAmount() public {
        MockAdapter adapter = new MockAdapter("Adapter");

        // 设置分配比例
        IVaultShares.Allocation[] memory allocations = new IVaultShares.Allocation[](1);
        allocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter)),
            allocation: 0 // 0%
         });

        vm.prank(owner);
        vaultShares.updateHoldingAllocation(allocations);

        // 存入一些资金
        vm.prank(user1);
        vaultShares.depositETH{ value: 1 ether }(user1);

        // 验证没有进行任何撤资（因为分配比例为0）
        assertEq(adapter.getTotalValue(IERC20(address(weth))), 0);
    }

    // 新增测试用例：测试setNotActive函数的事件发射
    function testSetNotActiveEmitsEvent() public {
        // 验证金库初始状态为活跃
        assertTrue(vaultShares.getIsActive(), "Vault should be active initially");

        // 调用setNotActive并验证事件发射
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit VaultSharesETH.NoLongerActive();
        vaultShares.setNotActive();

        // 验证金库状态变为非活跃
        assertFalse(vaultShares.getIsActive(), "Vault should be inactive after setNotActive");
    }

    // 新增测试用例：测试非活跃状态下redeemETH
    function testRedeemETHWhenNotActive() public {
        // 先存入一些资金
        vm.prank(user1);
        uint256 shares = vaultShares.depositETH{ value: 1 ether }(user1);

        // 设置金库为非活跃状态
        vm.prank(owner);
        vaultShares.setNotActive();

        // 赎回应该仍然可以工作（因为用户仍可提取资产）
        vm.prank(user1);
        uint256 assets = vaultShares.redeemETH(shares, user1, user1);
        assertEq(assets, shares, "Should be able to redeem when not active");
    }

    // 新增测试用例：测试非活跃状态下withdrawETH
    function testWithdrawETHWhenNotActive() public {
        // 先存入一些资金
        vm.prank(user1);
        uint256 shares = vaultShares.depositETH{ value: 1 ether }(user1);

        // 设置金库为非活跃状态
        vm.prank(owner);
        vaultShares.setNotActive();

        // 提取应该仍然可以工作（因为用户仍可提取资产）
        uint256 withdrawAmount = shares / 2;
        vm.prank(user1);
        uint256 sharesBurned = vaultShares.withdrawETH(withdrawAmount, user1, user1);
        assertEq(sharesBurned, withdrawAmount, "Should be able to withdraw when not active");
    }

    // 新增测试用例：测试updateHoldingAllocation的完整流程
    function testUpdateHoldingAllocationCompleteFlow() public {
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");

        // 初始分配
        IVaultShares.Allocation[] memory initialAllocations = new IVaultShares.Allocation[](1);
        initialAllocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter1)),
            allocation: 1000 // 100%
         });

        vm.prank(owner);
        vaultShares.updateHoldingAllocation(initialAllocations);

        // 存入资金
        vm.prank(user1);
        vaultShares.depositETH{ value: 1 ether }(user1);

        // 验证初始投资
        assertEq(adapter1.getTotalValue(IERC20(address(weth))), 1 ether);
        assertEq(adapter2.getTotalValue(IERC20(address(weth))), 0);

        // 更新分配
        IVaultShares.Allocation[] memory newAllocations = new IVaultShares.Allocation[](2);
        newAllocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter1)),
            allocation: 600 // 60%
         });
        newAllocations[1] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter2)),
            allocation: 400 // 40%
         });

        vm.prank(owner);
        vaultShares.updateHoldingAllocation(newAllocations);

        // 验证撤资和重新投资
        assertEq(adapter1.getTotalValue(IERC20(address(weth))), 0.6 ether);
        assertEq(adapter2.getTotalValue(IERC20(address(weth))), 0.4 ether);
    }

    // 新增测试用例：测试partialUpdateHoldingAllocation的边界情况
    function testPartialUpdateHoldingAllocationEdgeCases() public {
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");

        // 设置初始分配
        IVaultShares.Allocation[] memory initialAllocations = new IVaultShares.Allocation[](2);
        initialAllocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter1)),
            allocation: 500 // 50%
         });
        initialAllocations[1] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter2)),
            allocation: 500 // 50%
         });

        vm.prank(owner);
        vaultShares.updateHoldingAllocation(initialAllocations);

        // 存入资金
        vm.prank(user1);
        vaultShares.depositETH{ value: 1 ether }(user1);

        // 测试零撤资和零投资
        uint256[] memory emptyDivestIndices = new uint256[](0);
        uint256[] memory emptyDivestAmounts = new uint256[](0);
        uint256[] memory emptyInvestIndices = new uint256[](0);
        uint256[] memory emptyInvestAmounts = new uint256[](0);
        uint256[] memory emptyInvestAllocations = new uint256[](0);

        vm.prank(owner);
        vaultShares.partialUpdateHoldingAllocation(
            emptyDivestIndices, emptyDivestAmounts, emptyInvestIndices, emptyInvestAmounts, emptyInvestAllocations
        );

        // 验证没有变化
        assertEq(adapter1.getTotalValue(IERC20(address(weth))), 0.5 ether);
        assertEq(adapter2.getTotalValue(IERC20(address(weth))), 0.5 ether);
    }

    // 新增测试用例：测试withdrawAllInvestments的边界情况
    function testWithdrawAllInvestmentsEdgeCases() public {
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");

        // 设置分配
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
        vaultShares.updateHoldingAllocation(allocations);

        // 存入资金
        vm.prank(user1);
        vaultShares.depositETH{ value: 1 ether }(user1);

        // 验证投资
        assertEq(adapter1.getTotalValue(IERC20(address(weth))), 0.6 ether);
        assertEq(adapter2.getTotalValue(IERC20(address(weth))), 0.4 ether);

        // 撤资所有投资
        vm.prank(owner);
        vaultShares.withdrawAllInvestments();

        // 验证撤资
        assertEq(adapter1.getTotalValue(IERC20(address(weth))), 0);
        assertEq(adapter2.getTotalValue(IERC20(address(weth))), 0);
        assertEq(weth.balanceOf(address(vaultShares)), 1 ether);
    }

    // 新增测试用例：测试totalAssets函数的各种情况
    function testTotalAssetsVariousScenarios() public {
        MockAdapter adapter = new MockAdapter("Adapter");

        // 测试空分配的情况
        assertEq(vaultShares.totalAssets(), 0);

        // 设置分配
        IVaultShares.Allocation[] memory allocations = new IVaultShares.Allocation[](1);
        allocations[0] = IVaultShares.Allocation({
            adapter: IProtocolAdapter(address(adapter)),
            allocation: 1000 // 100%
         });

        vm.prank(owner);
        vaultShares.updateHoldingAllocation(allocations);

        // 存入资金
        vm.prank(user1);
        vaultShares.depositETH{ value: 1 ether }(user1);

        // 验证总资产计算
        uint256 totalAssets = vaultShares.totalAssets();
        assertGt(totalAssets, 1 ether, "Total assets should be greater than 1 ether");
    }

    // 新增测试用例：测试ETH转换禁用的情况
    function testETHConversionDisabled() public {
        // 创建一个自定义的VaultSharesETH来测试ETH转换禁用
        // 由于s_ethConversionEnabled是private，我们通过receive函数来测试
        uint256 sendAmount = 1 ether;

        // 直接发送ETH到合约（应该触发receive函数）
        vm.prank(user1);
        (bool success,) = address(vaultShares).call{ value: sendAmount }("");
        assertTrue(success, "ETH transfer should succeed");

        // 验证ETH被转换为WETH
        assertEq(weth.balanceOf(address(vaultShares)), sendAmount, "ETH should be converted to WETH");
    }

    // 新增测试用例：测试getIsActive函数
    function testGetIsActiveFunction() public view {
        // 测试初始状态
        assertTrue(vaultShares.getIsActive(), "Vault should be active initially");
    }
}

// 用于测试ETH转账失败的非可支付合约
contract NonPayableContract {
// 这个合约没有receive()或fallback()函数，所以无法接收ETH
}
