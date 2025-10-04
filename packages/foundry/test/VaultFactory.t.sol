// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { VaultFactory } from "../contracts/protocol/VaultFactory.sol";
import { VaultImplementation } from "../contracts/protocol/VaultImplementation.sol";
import { AIAgentVaultManager } from "../contracts/protocol/AIAgentVaultManager.sol";
import { MockToken } from "./mock/MockToken.sol";
import { MockAdapter } from "./mock/MockAdapter.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IVaultShares } from "../contracts/interfaces/IVaultShares.sol";

/**
 * @title VaultFactoryTest
 * @dev 测试金库工厂合约的功能
 */
contract VaultFactoryTest is Test {
    VaultFactory public vaultFactory;
    VaultImplementation public vaultImplementation;
    AIAgentVaultManager public vaultManager;
    MockToken public mockToken;
    MockAdapter public mockAdapter;

    address public owner = address(0x1);
    address public user = address(0x2);

    function setUp() public {
        // 部署实现合约
        vaultImplementation = new VaultImplementation();

        // 部署金库管理者合约
        vaultManager = new AIAgentVaultManager();

        // 部署工厂合约
        vaultFactory = new VaultFactory(address(vaultImplementation), address(vaultManager));

        // 部署测试代币
        mockToken = new MockToken("Test Token", "TEST");

        // 部署测试适配器
        mockAdapter = new MockAdapter("Test Adapter");

        // 给用户一些代币
        mockToken.mint(user, 1000e18);
    }

    function testCreateVault() public {
        // 创建金库
        address vault = vaultFactory.createVault(
            mockToken,
            "Test Vault",
            "TV",
            100 // 1% 费率
        );

        // 验证金库已创建
        assertTrue(vault != address(0));
        assertEq(vaultFactory.getVault(mockToken), vault);
        assertTrue(vaultFactory.hasVault(mockToken));
    }

    function testCreateVaultWithInvalidParams() public {
        // 测试无效的代币地址
        vm.expectRevert();
        vaultFactory.createVault(IERC20(address(0)), "Test Vault", "TV", 100);

        // 测试空的金库名称
        vm.expectRevert();
        vaultFactory.createVault(mockToken, "", "TV", 100);

        // 测试空的金库符号
        vm.expectRevert();
        vaultFactory.createVault(mockToken, "Test Vault", "", 100);

        // 测试过高的费率
        vm.expectRevert();
        vaultFactory.createVault(
            mockToken,
            "Test Vault",
            "TV",
            10001 // 超过100%
        );
    }

    function testCreateVaultTwice() public {
        // 第一次创建应该成功
        vaultFactory.createVault(mockToken, "Test Vault", "TV", 100);

        // 第二次创建应该失败
        vm.expectRevert();
        vaultFactory.createVault(mockToken, "Test Vault 2", "TV2", 100);
    }

    function testBatchCreateVaults() public {
        // 创建多个测试代币
        MockToken token1 = new MockToken("Token 1", "TK1");
        MockToken token2 = new MockToken("Token 2", "TK2");
        MockToken token3 = new MockToken("Token 3", "TK3");

        IERC20[] memory assets = new IERC20[](3);
        assets[0] = token1;
        assets[1] = token2;
        assets[2] = token3;

        string[] memory names = new string[](3);
        names[0] = "Vault 1";
        names[1] = "Vault 2";
        names[2] = "Vault 3";

        string[] memory symbols = new string[](3);
        symbols[0] = "V1";
        symbols[1] = "V2";
        symbols[2] = "V3";

        uint256[] memory fees = new uint256[](3);
        fees[0] = 100;
        fees[1] = 200;
        fees[2] = 300;

        // 批量创建金库
        address[] memory vaults = vaultFactory.createVaultsBatch(assets, names, symbols, fees);

        // 验证所有金库都已创建
        assertEq(vaults.length, 3);
        for (uint256 i = 0; i < 3; i++) {
            assertTrue(vaults[i] != address(0));
            assertEq(vaultFactory.getVault(assets[i]), vaults[i]);
        }
    }

    function testCreateMultipleVaults() public {
        // 创建几个金库
        MockToken token1 = new MockToken("Token 1", "TK1");
        MockToken token2 = new MockToken("Token 2", "TK2");

        address vault1 = vaultFactory.createVault(token1, "Vault 1", "V1", 100);
        address vault2 = vaultFactory.createVault(token2, "Vault 2", "V2", 200);

        // 验证金库地址
        assertTrue(vault1 != address(0));
        assertTrue(vault2 != address(0));
        assertTrue(vault1 != vault2);

        // 验证金库是否正确注册
        assertEq(vaultFactory.getVault(token1), vault1);
        assertEq(vaultFactory.getVault(token2), vault2);
        assertTrue(vaultFactory.hasVault(token1));
        assertTrue(vaultFactory.hasVault(token2));
    }

    function testVaultInitialization() public {
        // 创建金库
        address vault = vaultFactory.createVault(mockToken, "Test Vault", "TV", 100);

        // 验证金库已正确初始化
        VaultImplementation vaultImpl = VaultImplementation(vault);
        assertTrue(vaultImpl.getIsActive());

        // 验证金库名称和符号
        assertEq(vaultImpl.name(), "Test Vault");
        assertEq(vaultImpl.symbol(), "TV");
    }
}
