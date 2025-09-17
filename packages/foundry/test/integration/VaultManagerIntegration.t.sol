// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../../contracts/protocol/AIAgentVaultManager.sol";
import "../../contracts/protocol/VaultShares.sol";
import "../mock/MockAdapter.sol";
import "../mock/MockToken.sol";

contract VaultManagerIntegrationTest is Test {
    AIAgentVaultManager public manager;
    MockToken public token;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = address(0x123);

        manager = new AIAgentVaultManager();
        token = new MockToken("Test Token", "TEST");

        // Transfer some tokens to the user for testing
        token.transfer(user, 1000 * 10 ** 18);
    }

    /**
     * @notice 测试完整的金库管理流程
     * 1. 创建金库
     * 2. 添加适配器
     * 3. 更新资产分配
     * 4. 用户存款
     * 5. 部分更新资产分配
     * 6. 撤回所有投资
     * 7. 设置金库为非活跃状态
     */
    function testFullVaultManagementFlow() public {
        // 1. 创建金库
        vm.prank(owner);
        address vaultAddress = manager.createVault(token);
        
        assertNotEq(vaultAddress, address(0), "Vault should be created");
        emit log_named_address("Vault created at", vaultAddress);

        // 2. 添加适配器
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");

        vm.prank(owner);
        manager.addAdapter(IProtocolAdapter(address(adapter1)));

        vm.prank(owner);
        manager.addAdapter(IProtocolAdapter(address(adapter2)));

        // 验证适配器已添加
        assertTrue(manager.isAdapterApproved(IProtocolAdapter(address(adapter1))), "Adapter 1 should be approved");
        assertTrue(manager.isAdapterApproved(IProtocolAdapter(address(adapter2))), "Adapter 2 should be approved");
        assertEq(manager.getAllAdapters().length, 2, "Should have 2 adapters");

        // 3. 更新资产分配
        uint256[] memory adapterIndices = new uint256[](2);
        adapterIndices[0] = 0; // Adapter 1
        adapterIndices[1] = 1; // Adapter 2

        uint256[] memory allocationData = new uint256[](2);
        allocationData[0] = 600; // 60%
        allocationData[1] = 400; // 40%

        vm.prank(owner);
        manager.updateHoldingAllocation(token, adapterIndices, allocationData);

        // 4. 用户存款
        vm.prank(user);
        token.approve(vaultAddress, 100 * 10 ** 18);

        vm.prank(user);
        uint256 shares = VaultShares(vaultAddress).deposit(100 * 10 ** 18, user);

        assertGt(shares, 0, "User should receive shares");
        emit log_named_uint("User received shares", shares);

        // 验证资金已按分配比例投资到适配器中
        assertEq(adapter1.getTotalValue(IERC20(address(token))), 60 * 10 ** 18, "Adapter 1 should have 60 tokens");
        assertEq(adapter2.getTotalValue(IERC20(address(token))), 40 * 10 ** 18, "Adapter 2 should have 40 tokens");

        // 5. 部分更新资产分配 - 将部分资金从Adapter 1转移到Adapter 2
        uint256[] memory divestAdapterIndices = new uint256[](1);
        divestAdapterIndices[0] = 0; // Adapter 1

        uint256[] memory divestAmounts = new uint256[](1);
        divestAmounts[0] = 20 * 10 ** 18; // 从Adapter 1撤资20 tokens

        uint256[] memory investAdapterIndices = new uint256[](1);
        investAdapterIndices[0] = 1; // Adapter 2

        uint256[] memory investAmounts = new uint256[](1);
        investAmounts[0] = 20 * 10 ** 18; // 向Adapter 2投资20 tokens

        uint256[] memory investAllocations = new uint256[](1);
        investAllocations[0] = 600; // Adapter 2的新分配比例为60%

        vm.prank(owner);
        manager.partialUpdateHoldingAllocation(
            token,
            divestAdapterIndices,
            divestAmounts,
            investAdapterIndices,
            investAmounts,
            investAllocations
        );

        // 验证部分更新后的资金分配
        assertEq(adapter1.getTotalValue(IERC20(address(token))), 40 * 10 ** 18, "Adapter 1 should have 40 tokens after partial update");
        assertEq(adapter2.getTotalValue(IERC20(address(token))), 60 * 10 ** 18, "Adapter 2 should have 60 tokens after partial update");

        // 6. 撤回所有投资
        vm.prank(owner);
        manager.withdrawAllInvestments(token);

        // 验证所有投资已撤回
        assertEq(adapter1.getTotalValue(IERC20(address(token))), 0, "Adapter 1 should have 0 tokens after withdrawal");
        assertEq(adapter2.getTotalValue(IERC20(address(token))), 0, "Adapter 2 should have 0 tokens after withdrawal");

        // 7. 设置金库为非活跃状态
        vm.prank(owner);
        manager.setVaultNotActive(token);

        // 验证金库已设为非活跃状态
        assertFalse(VaultShares(vaultAddress).getIsActive(), "Vault should be inactive");
    }

    /**
     * @notice 测试通过管理器执行适配器调用
     */
    function testExecuteAdapterCalls() public {
        // 添加适配器
        MockAdapter adapter = new MockAdapter("Test Adapter");

        vm.prank(owner);
        manager.addAdapter(IProtocolAdapter(address(adapter)));

        // 通过管理器执行适配器的getName调用
        bytes memory data = abi.encodeWithSelector(adapter.getName.selector);

        vm.prank(owner);
        bytes memory result = manager.execute(0, 0, data);

        string memory name = abi.decode(result, (string));
        assertEq(name, "Test Adapter", "Adapter name should match");

        // 通过管理器执行批量调用
        MockAdapter adapter2 = new MockAdapter("Test Adapter 2");

        vm.prank(owner);
        manager.addAdapter(IProtocolAdapter(address(adapter2)));

        uint256[] memory adapterIndices = new uint256[](2);
        adapterIndices[0] = 0;
        adapterIndices[1] = 1;

        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        bytes[] memory callData = new bytes[](2);
        callData[0] = abi.encodeWithSelector(adapter.getName.selector);
        callData[1] = abi.encodeWithSelector(adapter2.getName.selector);

        vm.prank(owner);
        bytes[] memory results = manager.executeBatch(adapterIndices, values, callData);

        string memory name1 = abi.decode(results[0], (string));
        string memory name2 = abi.decode(results[1], (string));
        assertEq(name1, "Test Adapter", "First adapter name should match");
        assertEq(name2, "Test Adapter 2", "Second adapter name should match");
    }
}