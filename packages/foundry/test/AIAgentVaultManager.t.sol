// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../contracts/protocol/AIAgentVaultManager.sol";
import "../contracts/protocol/VaultShares.sol";
import { MockAdapter } from "./mock/MockAdapter.sol";
import { MockToken } from "./mock/MockToken.sol";

contract AIAgentVaultManagerTest is Test {
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

    function testCreateVault() public {
        vm.prank(owner);
        address vaultAddress = manager.createVault(token);

        assertTrue(vaultAddress != address(0));
        assertTrue(manager.getAllAdapters().length == 0);
    }

    function testCreateVaultNotOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        manager.createVault(token);
    }

    function testAddAdapter() public {
        MockAdapter adapter = new MockAdapter("Test Adapter");

        vm.prank(owner);
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

    function testAddAdapterAlreadyApproved() public {
        MockAdapter adapter = new MockAdapter("Test Adapter");

        vm.prank(owner);
        manager.addAdapter(IProtocolAdapter(address(adapter)));

        vm.prank(owner);
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
        vm.prank(owner);
        manager.createVault(token);

        // Add adapters
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");

        vm.prank(owner);
        manager.addAdapter(IProtocolAdapter(address(adapter1)));

        vm.prank(owner);
        manager.addAdapter(IProtocolAdapter(address(adapter2)));

        // Update allocation
        uint256[] memory adapterIndices = new uint256[](2);
        adapterIndices[0] = 0;
        adapterIndices[1] = 1;

        uint256[] memory allocationData = new uint256[](2);
        allocationData[0] = 600; // 60%
        allocationData[1] = 400; // 40%

        vm.prank(owner);
        manager.updateHoldingAllocation(token, adapterIndices, allocationData);

        // Allocation updated event should be emitted
        // We can't directly check the vault's internal state without exposing it
    }

    function testUpdateHoldingAllocationInvalidParams() public {
        // Create vault first
        vm.prank(owner);
        manager.createVault(token);

        // Add adapters
        MockAdapter adapter1 = new MockAdapter("Adapter 1");

        vm.prank(owner);
        manager.addAdapter(IProtocolAdapter(address(adapter1)));

        // Try with mismatched array lengths
        uint256[] memory adapterIndices = new uint256[](1);
        adapterIndices[0] = 0;

        uint256[] memory allocationData = new uint256[](2);
        allocationData[0] = 600;
        allocationData[1] = 400;

        vm.prank(owner);
        vm.expectRevert(AIAgentVaultManager.AIAgentVaultManager__InvalidAllocation.selector);
        manager.updateHoldingAllocation(token, adapterIndices, allocationData);
    }

    function testUpdateHoldingAllocationVaultNotRegistered() public {
        MockToken anotherToken = new MockToken("Another Token", "ANOTHER");

        uint256[] memory adapterIndices = new uint256[](1);
        adapterIndices[0] = 0;

        uint256[] memory allocationData = new uint256[](1);
        allocationData[0] = 1000;

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(AIAgentVaultManager.AIAgentVaultManager__VaultNotRegistered.selector, address(0))
        );
        manager.updateHoldingAllocation(anotherToken, adapterIndices, allocationData);
    }

    function testPartialUpdateHoldingAllocation() public {
        // Create vault first
        vm.prank(owner);
        address vaultAddress = manager.createVault(token);

        // Add adapters
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");

        vm.prank(owner);
        manager.addAdapter(IProtocolAdapter(address(adapter1)));

        vm.prank(owner);
        manager.addAdapter(IProtocolAdapter(address(adapter2)));

        // First set an allocation so we have something to divest from
        uint256[] memory initialAdapterIndices = new uint256[](2);
        initialAdapterIndices[0] = 0;
        initialAdapterIndices[1] = 1;

        uint256[] memory initialAllocationData = new uint256[](2);
        initialAllocationData[0] = 600; // 60%
        initialAllocationData[1] = 400; // 40%

        vm.prank(owner);
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

        vm.prank(owner);
        manager.partialUpdateHoldingAllocation(
            token, divestAdapterIndices, divestAmounts, investAdapterIndices, investAmounts, investAllocations
        );
    }

    function testPartialUpdateHoldingAllocationInvalidParams() public {
        // Create vault first
        vm.prank(owner);
        manager.createVault(token);

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

        vm.prank(owner);
        vm.expectRevert(AIAgentVaultManager.AIAgentVaultManager__InvalidAllocation.selector);
        manager.partialUpdateHoldingAllocation(
            token, divestAdapterIndices, divestAmounts, investAdapterIndices, investAmounts, investAllocations
        );
    }

    function testWithdrawAllInvestments() public {
        // Create vault first
        vm.prank(owner);
        manager.createVault(token);

        vm.prank(owner);
        manager.withdrawAllInvestments(token);
        // Should not revert
    }

    function testWithdrawAllInvestmentsVaultNotRegistered() public {
        MockToken anotherToken = new MockToken("Another Token", "ANOTHER");

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(AIAgentVaultManager.AIAgentVaultManager__VaultNotRegistered.selector, address(0))
        );
        manager.withdrawAllInvestments(anotherToken);
    }

    function testSetVaultNotActive() public {
        // Create vault first
        vm.prank(owner);
        manager.createVault(token);

        vm.prank(owner);
        manager.setVaultNotActive(token);
        // Should emit event and not revert
    }

    function testSetVaultNotActiveVaultNotRegistered() public {
        MockToken anotherToken = new MockToken("Another Token", "ANOTHER");

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(AIAgentVaultManager.AIAgentVaultManager__VaultNotRegistered.selector, address(0))
        );
        manager.setVaultNotActive(anotherToken);
    }

    function testExecute() public {
        // Add adapter
        MockAdapter adapter = new MockAdapter("Test Adapter");

        vm.prank(owner);
        manager.addAdapter(IProtocolAdapter(address(adapter)));

        // Execute call
        bytes memory data = abi.encodeWithSelector(adapter.getName.selector);

        vm.prank(owner);
        bytes memory result = manager.execute(0, 0, data);

        // Verify the result
        string memory name = abi.decode(result, (string));
        assertEq(name, "Test Adapter");
        // Should not revert
    }

    function testExecuteInvalidIndex() public {
        bytes memory data = abi.encodeWithSignature("getName()");

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(AIAgentVaultManager.AIAgentVaultManager__InvalidAdapterIndex.selector, 0)
        );
        manager.execute(0, 0, data);
    }

    function testExecuteBatch() public {
        // Add adapters
        MockAdapter adapter1 = new MockAdapter("Adapter 1");
        MockAdapter adapter2 = new MockAdapter("Adapter 2");

        vm.prank(owner);
        manager.addAdapter(IProtocolAdapter(address(adapter1)));

        vm.prank(owner);
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

        vm.prank(owner);
        bytes[] memory results = manager.executeBatch(adapterIndices, values, data);

        // Verify the results
        assertEq(results.length, 2);
        string memory name1 = abi.decode(results[0], (string));
        string memory name2 = abi.decode(results[1], (string));
        assertEq(name1, "Adapter 1");
        assertEq(name2, "Adapter 2");
        // Should not revert
    }

    function testExecuteBatchLengthMismatch() public {
        uint256[] memory adapterIndices = new uint256[](1);
        adapterIndices[0] = 0;

        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        bytes[] memory data = new bytes[](1);
        data[0] = "";

        vm.prank(owner);
        vm.expectRevert(AIAgentVaultManager.AIAgentVaultManager__BatchLengthMismatch.selector);
        manager.executeBatch(adapterIndices, values, data);
    }
}
