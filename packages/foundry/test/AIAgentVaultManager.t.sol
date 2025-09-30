// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../contracts/protocol/AIAgentVaultManager.sol";
import "../contracts/protocol/VaultFactory.sol";
import "../contracts/protocol/VaultImplementation.sol";
import "../contracts/protocol/VaultSharesETH.sol";
import { MockAdapter } from "./mock/MockAdapter.sol";
import { MockToken } from "./mock/MockToken.sol";
import { MockWETH9 } from "./mock/MockWETH9.sol";

contract AIAgentVaultManagerTest is Test {
    AIAgentVaultManager public manager;
    VaultFactory public vaultFactory;
    MockToken public token;
    MockWETH9 public weth;
    address public owner;
    address public user;

    // Helper function to create and add a vault
    function _createAndAddVault(MockToken asset) internal returns (address) {
        address vault = vaultFactory.createVault(
            asset,
            string.concat("Test ", asset.name()),
            string.concat("TEST", asset.symbol()),
            1000 // 0.1% fee
        );

        // VaultFactory already transfers ownership to manager
        manager.addVault(asset, vault);
        return vault;
    }

    function setUp() public {
        owner = address(this);
        user = address(0x123);

        weth = new MockWETH9();
        token = new MockToken("Test Token", "TEST");

        // 部署工厂
        VaultImplementation implementation = new VaultImplementation();
        manager = new AIAgentVaultManager();
        vaultFactory = new VaultFactory(address(implementation), address(manager));

        // Transfer some tokens to the user for testing
        token.transfer(user, 1000 * 10 ** 18);
    }

    function testAddVault() public {
        // First create a vault using factory
        address vault = vaultFactory.createVault(token, "Test Vault", "TEST", 1000);

        // VaultFactory already transfers ownership to manager, so no need to transfer again

        // 不需要 vm.prank，因为测试合约就是所有者
        manager.addVault(token, vault);

        assertTrue(vault != address(0));
        assertTrue(manager.getAllAdapters().length == 0);
    }

    function testAddVaultNotOwner() public {
        address vault = vaultFactory.createVault(token, "Test Vault", "TEST", 1000);

        // VaultFactory already transfers ownership to manager, so no need to transfer again

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        manager.addVault(token, vault);
    }

    function testAddETHVault() public {
        // First create ETH vault manually
        VaultSharesETH ethVault = new VaultSharesETH(
            IVaultShares.ConstructorData({ asset: weth, Fee: 1000, vaultName: "Test ETH Vault", vaultSymbol: "TESTETH" })
        );

        manager.addVault(weth, address(ethVault));

        assertTrue(address(ethVault) != address(0));

        // 验证创建的合约确实是 VaultSharesETH
        assertEq(ethVault.name(), "Test ETH Vault");
        assertEq(ethVault.symbol(), "TESTETH");
        assertEq(address(ethVault.asset()), address(weth));
    }

    function testAddETHVaultNotOwner() public {
        VaultSharesETH ethVault = new VaultSharesETH(
            IVaultShares.ConstructorData({ asset: weth, Fee: 1000, vaultName: "Test ETH Vault", vaultSymbol: "TESTETH" })
        );

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        manager.addVault(weth, address(ethVault));
    }

    function testAddAdapter() public {
        MockAdapter adapter = new MockAdapter("Test Adapter");

        manager.addAdapter(IProtocolAdapter(address(adapter)));

        assertTrue(manager.isAdapterApproved(IProtocolAdapter(address(adapter))));
        assertEq(manager.getAllAdapters().length, 1);
        assertEq(address(manager.getAllAdapters()[0]), address(adapter));
    }

    function testAddAdapterNotOwner() public {
        MockAdapter adapter = new MockAdapter("Test Adapter");

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        manager.addAdapter(IProtocolAdapter(address(adapter)));
    }

    function testAddAdapterZeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                AIAgentVaultManager.AIAgentVaultManager__AdapterNotApproved.selector, IProtocolAdapter(address(0))
            )
        );
        manager.addAdapter(IProtocolAdapter(address(0)));
    }

    function testAddAdapterAlreadyApproved() public {
        MockAdapter adapter = new MockAdapter("Test Adapter");

        manager.addAdapter(IProtocolAdapter(address(adapter)));

        vm.expectRevert(
            abi.encodeWithSelector(
                AIAgentVaultManager.AIAgentVaultManager__AdapterAlreadyApproved.selector,
                IProtocolAdapter(address(adapter))
            )
        );
        manager.addAdapter(IProtocolAdapter(address(adapter)));
    }

    function testUpdateHoldingAllocation() public {
        // Create vault first
        _createAndAddVault(token);

        // Add adapters
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");

        manager.addAdapter(IProtocolAdapter(address(adapter1)));
        manager.addAdapter(IProtocolAdapter(address(adapter2)));

        // Update allocation
        uint256[] memory adapterIndices = new uint256[](2);
        adapterIndices[0] = 0;
        adapterIndices[1] = 1;

        uint256[] memory allocationData = new uint256[](2);
        allocationData[0] = 600; // 60%
        allocationData[1] = 400; // 40%

        manager.updateHoldingAllocation(token, adapterIndices, allocationData);

        // Allocation updated event should be emitted
        // We can't directly check the vault's internal state without exposing it
    }

    function testUpdateHoldingAllocationInvalidParams() public {
        // Create vault first
        _createAndAddVault(token);

        // Add adapters
        MockAdapter adapter1 = new MockAdapter("Adapter 1");

        manager.addAdapter(IProtocolAdapter(address(adapter1)));

        // Try with mismatched array lengths
        uint256[] memory adapterIndices = new uint256[](1);
        adapterIndices[0] = 0;

        uint256[] memory allocationData = new uint256[](2);
        allocationData[0] = 600;
        allocationData[1] = 400;

        vm.expectRevert(AIAgentVaultManager.AIAgentVaultManager__InvalidAllocation.selector);
        manager.updateHoldingAllocation(token, adapterIndices, allocationData);
    }

    function testUpdateHoldingAllocationInvalidAdapterIndex() public {
        // Create vault first
        _createAndAddVault(token);

        // Add one adapter
        MockAdapter adapter = new MockAdapter("Test Adapter");
        manager.addAdapter(IProtocolAdapter(address(adapter)));

        // Try to use an invalid adapter index
        uint256[] memory adapterIndices = new uint256[](1);
        adapterIndices[0] = 5; // Invalid index

        uint256[] memory allocationData = new uint256[](1);
        allocationData[0] = 1000;

        vm.expectRevert(
            abi.encodeWithSelector(AIAgentVaultManager.AIAgentVaultManager__InvalidAdapterIndex.selector, 5)
        );
        manager.updateHoldingAllocation(token, adapterIndices, allocationData);
    }

    function testUpdateHoldingAllocationVaultNotRegistered() public {
        MockToken anotherToken = new MockToken("Another Token", "ANOTHER");

        uint256[] memory adapterIndices = new uint256[](1);
        adapterIndices[0] = 0;

        uint256[] memory allocationData = new uint256[](1);
        allocationData[0] = 1000;

        vm.expectRevert(
            abi.encodeWithSelector(AIAgentVaultManager.AIAgentVaultManager__VaultNotRegistered.selector, address(0))
        );
        manager.updateHoldingAllocation(anotherToken, adapterIndices, allocationData);
    }

    function testPartialUpdateHoldingAllocation() public {
        // Create vault first
        address vaultAddress = _createAndAddVault(token);

        // Add adapters
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");

        manager.addAdapter(IProtocolAdapter(address(adapter1)));
        manager.addAdapter(IProtocolAdapter(address(adapter2)));

        // First set an allocation so we have something to divest from
        uint256[] memory initialAdapterIndices = new uint256[](2);
        initialAdapterIndices[0] = 0;
        initialAdapterIndices[1] = 1;

        uint256[] memory initialAllocationData = new uint256[](2);
        initialAllocationData[0] = 600; // 60%
        initialAllocationData[1] = 400; // 40%

        manager.updateHoldingAllocation(token, initialAdapterIndices, initialAllocationData);

        // Transfer some tokens to vault so it can invest
        token.transfer(vaultAddress, 1000 * 10 ** 18);

        // Manually invest in the first adapter to have something to divest from
        vm.prank(vaultAddress);
        adapter1.invest(token, 500 * 10 ** 18);

        // Partial update allocation
        uint256[] memory divestAdapterIndices = new uint256[](1);
        divestAdapterIndices[0] = 0;

        uint256[] memory divestAmounts = new uint256[](1);
        divestAmounts[0] = 100 * 10 ** 18;

        uint256[] memory investAdapterIndices = new uint256[](1);
        investAdapterIndices[0] = 1;

        uint256[] memory investAmounts = new uint256[](1);
        investAmounts[0] = 100 * 10 ** 18;

        uint256[] memory investAllocations = new uint256[](1);
        investAllocations[0] = 500;

        manager.partialUpdateHoldingAllocation(
            token, divestAdapterIndices, divestAmounts, investAdapterIndices, investAmounts, investAllocations
        );
    }

    function testPartialUpdateHoldingAllocationInvalidParams() public {
        // Create vault first
        _createAndAddVault(token);

        // Try with mismatched divest array lengths
        uint256[] memory divestAdapterIndices = new uint256[](1);
        divestAdapterIndices[0] = 0;

        uint256[] memory divestAmounts = new uint256[](2);
        divestAmounts[0] = 100;
        divestAmounts[1] = 200;

        uint256[] memory investAdapterIndices = new uint256[](1);
        investAdapterIndices[0] = 1;

        uint256[] memory investAmounts = new uint256[](1);
        investAmounts[0] = 100;

        uint256[] memory investAllocations = new uint256[](1);
        investAllocations[0] = 500;

        vm.expectRevert(AIAgentVaultManager.AIAgentVaultManager__InvalidAllocation.selector);
        manager.partialUpdateHoldingAllocation(
            token, divestAdapterIndices, divestAmounts, investAdapterIndices, investAmounts, investAllocations
        );
    }

    function testPartialUpdateHoldingAllocationVaultNotRegistered() public {
        MockToken anotherToken = new MockToken("Another Token", "ANOTHER");

        uint256[] memory divestAdapterIndices = new uint256[](1);
        divestAdapterIndices[0] = 0;

        uint256[] memory divestAmounts = new uint256[](1);
        divestAmounts[0] = 100;

        uint256[] memory investAdapterIndices = new uint256[](1);
        investAdapterIndices[0] = 1;

        uint256[] memory investAmounts = new uint256[](1);
        investAmounts[0] = 100;

        uint256[] memory investAllocations = new uint256[](1);
        investAllocations[0] = 500;

        vm.expectRevert(
            abi.encodeWithSelector(AIAgentVaultManager.AIAgentVaultManager__VaultNotRegistered.selector, address(0))
        );
        manager.partialUpdateHoldingAllocation(
            anotherToken, divestAdapterIndices, divestAmounts, investAdapterIndices, investAmounts, investAllocations
        );
    }

    function testWithdrawAllInvestments() public {
        // Create vault first
        _createAndAddVault(token);

        manager.withdrawAllInvestments(token);
        // Should not revert
    }

    function testWithdrawAllInvestmentsVaultNotRegistered() public {
        MockToken anotherToken = new MockToken("Another Token", "ANOTHER");

        vm.expectRevert(
            abi.encodeWithSelector(AIAgentVaultManager.AIAgentVaultManager__VaultNotRegistered.selector, address(0))
        );
        manager.withdrawAllInvestments(anotherToken);
    }

    function testSetVaultNotActive() public {
        // Create vault first
        _createAndAddVault(token);

        manager.setVaultNotActive(token);
        // Should emit event and not revert
    }

    function testSetVaultNotActiveVaultNotRegistered() public {
        MockToken anotherToken = new MockToken("Another Token", "ANOTHER");

        vm.expectRevert(
            abi.encodeWithSelector(AIAgentVaultManager.AIAgentVaultManager__VaultNotRegistered.selector, address(0))
        );
        manager.setVaultNotActive(anotherToken);
    }

    function testExecute() public {
        // Add adapter
        MockAdapter adapter = new MockAdapter("Test Adapter");

        manager.addAdapter(IProtocolAdapter(address(adapter)));

        // Execute call
        bytes memory data = abi.encodeWithSelector(adapter.getName.selector);

        manager.execute(0, 0, data);

        // Should not revert - the call succeeded
        // Should not revert
    }

    function testExecuteInvalidIndex() public {
        bytes memory data = abi.encodeWithSignature("getName()");

        vm.expectRevert(
            abi.encodeWithSelector(AIAgentVaultManager.AIAgentVaultManager__InvalidAdapterIndex.selector, 0)
        );
        manager.execute(0, 0, data);
    }

    function testExecuteAdapterCallFailed() public {
        // Add adapter
        MockAdapter adapter = new MockAdapter("Test Adapter");
        manager.addAdapter(IProtocolAdapter(address(adapter)));

        // Execute call with a function that doesn't exist
        bytes memory data = abi.encodeWithSignature("nonExistentFunction()");

        vm.expectRevert(abi.encodeWithSelector(AIAgentVaultManager.AIAgentVaultManager__AdapterCallFailed.selector));
        manager.execute(0, 0, data);
    }

    function testExecuteBatch() public {
        // Add adapters
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");

        manager.addAdapter(IProtocolAdapter(address(adapter1)));
        manager.addAdapter(IProtocolAdapter(address(adapter2)));

        // Prepare batch execution
        uint256[] memory adapterIndices = new uint256[](2);
        adapterIndices[0] = 0;
        adapterIndices[1] = 1;

        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(adapter1.getName.selector);
        data[1] = abi.encodeWithSelector(adapter2.getName.selector);

        manager.executeBatch(adapterIndices, values, data);

        // Should not revert - the calls succeeded
        // Should not revert
    }

    function testExecuteBatchInvalidAdapterIndex() public {
        // Add one adapter
        MockAdapter adapter = new MockAdapter("Test Adapter");
        manager.addAdapter(IProtocolAdapter(address(adapter)));

        // Prepare batch execution with invalid index
        uint256[] memory adapterIndices = new uint256[](2); // Changed to 2 elements
        adapterIndices[0] = 0;
        adapterIndices[1] = 5; // Invalid index

        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(adapter.getName.selector);
        data[1] = abi.encodeWithSelector(adapter.getName.selector);

        vm.expectRevert(
            abi.encodeWithSelector(AIAgentVaultManager.AIAgentVaultManager__InvalidAdapterIndex.selector, 5)
        );
        manager.executeBatch(adapterIndices, values, data);
    }

    function testExecuteBatchLengthMismatch() public {
        uint256[] memory adapterIndices = new uint256[](1);
        adapterIndices[0] = 0;

        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        bytes[] memory data = new bytes[](1);
        data[0] = "";

        vm.expectRevert(AIAgentVaultManager.AIAgentVaultManager__BatchLengthMismatch.selector);
        manager.executeBatch(adapterIndices, values, data);
    }

    // 测试executeBatch中适配器调用失败的情况
    function testExecuteBatchAdapterCallFailed() public {
        // Add adapter
        MockAdapter adapter = new MockAdapter("Test Adapter");
        manager.addAdapter(IProtocolAdapter(address(adapter)));

        // Prepare batch execution with a call that will fail
        uint256[] memory adapterIndices = new uint256[](1);
        adapterIndices[0] = 0;

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        // Create a call to a non-existent function to make it fail
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("nonExistentFunction()");

        vm.expectRevert(abi.encodeWithSelector(AIAgentVaultManager.AIAgentVaultManager__AdapterCallFailed.selector));
        manager.executeBatch(adapterIndices, values, data);
    }

    // ========== 额外的边界条件和错误处理测试 ==========

    function testPartialUpdateHoldingAllocationInvalidInvestParams() public {
        // Create vault first
        _createAndAddVault(token);

        // Add adapters
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");

        manager.addAdapter(IProtocolAdapter(address(adapter1)));
        manager.addAdapter(IProtocolAdapter(address(adapter2)));

        // Try with mismatched invest array lengths
        uint256[] memory divestAdapterIndices = new uint256[](1);
        divestAdapterIndices[0] = 0;

        uint256[] memory divestAmounts = new uint256[](1);
        divestAmounts[0] = 100;

        uint256[] memory investAdapterIndices = new uint256[](1);
        investAdapterIndices[0] = 1;

        uint256[] memory investAmounts = new uint256[](2); // 长度不匹配
        investAmounts[0] = 100;
        investAmounts[1] = 200;

        uint256[] memory investAllocations = new uint256[](1);
        investAllocations[0] = 500;

        vm.expectRevert(AIAgentVaultManager.AIAgentVaultManager__InvalidAllocation.selector);
        manager.partialUpdateHoldingAllocation(
            token, divestAdapterIndices, divestAmounts, investAdapterIndices, investAmounts, investAllocations
        );
    }

    function testPartialUpdateHoldingAllocationInvalidDivestParams() public {
        // Create vault first
        _createAndAddVault(token);

        // Add adapters
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");

        manager.addAdapter(IProtocolAdapter(address(adapter1)));
        manager.addAdapter(IProtocolAdapter(address(adapter2)));

        // Try with mismatched divest array lengths
        uint256[] memory divestAdapterIndices = new uint256[](2); // 长度不匹配
        divestAdapterIndices[0] = 0;
        divestAdapterIndices[1] = 1;

        uint256[] memory divestAmounts = new uint256[](1);
        divestAmounts[0] = 100;

        uint256[] memory investAdapterIndices = new uint256[](1);
        investAdapterIndices[0] = 1;

        uint256[] memory investAmounts = new uint256[](1);
        investAmounts[0] = 100;

        uint256[] memory investAllocations = new uint256[](1);
        investAllocations[0] = 500;

        vm.expectRevert(AIAgentVaultManager.AIAgentVaultManager__InvalidAllocation.selector);
        manager.partialUpdateHoldingAllocation(
            token, divestAdapterIndices, divestAmounts, investAdapterIndices, investAmounts, investAllocations
        );
    }

    function testExecuteBatchWithEmptyArrays() public {
        // Test with empty arrays
        uint256[] memory adapterIndices = new uint256[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory data = new bytes[](0);

        manager.executeBatch(adapterIndices, values, data);

        // Should not revert - the calls succeeded
    }

    function testExecuteBatchWithSingleAdapter() public {
        // Add adapter
        MockAdapter adapter = new MockAdapter("Test Adapter");
        manager.addAdapter(IProtocolAdapter(address(adapter)));

        // Prepare batch execution with single adapter
        uint256[] memory adapterIndices = new uint256[](1);
        adapterIndices[0] = 0;

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(adapter.getName.selector);

        manager.executeBatch(adapterIndices, values, data);

        // Should not revert - the calls succeeded
    }

    function testExecuteWithValue() public {
        // Add adapter
        MockAdapter adapter = new MockAdapter("Test Adapter");
        manager.addAdapter(IProtocolAdapter(address(adapter)));

        // Fund the manager contract with ETH
        vm.deal(address(manager), 10 ether);

        // Execute call with ETH value
        bytes memory data = abi.encodeWithSelector(adapter.getNamePayable.selector);

        manager.execute(0, 1 ether, data);

        // Should not revert - the call succeeded
    }

    function testExecuteBatchWithValue() public {
        // Add adapter
        MockAdapter adapter = new MockAdapter("Test Adapter");
        manager.addAdapter(IProtocolAdapter(address(adapter)));

        // Fund the manager contract with ETH
        vm.deal(address(manager), 10 ether);

        // Prepare batch execution with ETH value
        uint256[] memory adapterIndices = new uint256[](1);
        adapterIndices[0] = 0;

        uint256[] memory values = new uint256[](1);
        values[0] = 1 ether;

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(adapter.getNamePayable.selector);

        manager.executeBatch(adapterIndices, values, data);

        // Should not revert - the calls succeeded
    }

    function testGetAllAdaptersEmpty() public view {
        // Test getting adapters when none are added
        IProtocolAdapter[] memory adapters = manager.getAllAdapters();
        assertEq(adapters.length, 0);
    }

    function testGetAllAdaptersMultiple() public {
        // Add multiple adapters
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");
        MockAdapter adapter3 = new MockAdapter("Adapter 3");

        manager.addAdapter(IProtocolAdapter(address(adapter1)));
        manager.addAdapter(IProtocolAdapter(address(adapter2)));

        manager.addAdapter(IProtocolAdapter(address(adapter3)));

        // Get all adapters
        IProtocolAdapter[] memory adapters = manager.getAllAdapters();
        assertEq(adapters.length, 3);
        assertEq(address(adapters[0]), address(adapter1));
        assertEq(address(adapters[1]), address(adapter2));
        assertEq(address(adapters[2]), address(adapter3));
    }

    function testIsAdapterApprovedFalse() public {
        // Test checking approval for non-added adapter
        MockAdapter adapter = new MockAdapter("Test Adapter");
        assertFalse(manager.isAdapterApproved(IProtocolAdapter(address(adapter))));
    }

    function testIsAdapterApprovedTrue() public {
        // Add adapter and check approval
        MockAdapter adapter = new MockAdapter("Test Adapter");
        manager.addAdapter(IProtocolAdapter(address(adapter)));

        assertTrue(manager.isAdapterApproved(IProtocolAdapter(address(adapter))));
    }
}
