//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../contracts/protocol/AIAgentVaultManager.sol";
import "../contracts/protocol/VaultFactory.sol";
import "../contracts/protocol/VaultImplementation.sol";
import "../contracts/protocol/VaultSharesETH.sol";
import "../contracts/interfaces/IVaultShares.sol";
import "../contracts/protocol/investableUniverseAdapters/AaveAdapter.sol";
import "../contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol";
import "../contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol";
import "../test/mock/MockToken.sol";
import "../test/mock/MockWETH9.sol";
import "../test/mock/MockAavePool.sol";
import "../test/mock/MockUniswapV2.sol";
import "../test/mock/RealisticUniswapV3.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title SimulateTrading
 * @notice 使用已部署的合约执行模拟交易
 * @dev 连接到已部署的合约并执行真实用户操作流程
 *
 * 测试账户：
 * - 1个管理者账户
 * - 3个用户账户
 *
 * 地址获取方式（按优先级）：
 * 1. 从 DeployAIVault.s.sol 的 getDeployedAddresses 方法获取
 * 2. 从环境变量获取
 * 3. 从配置文件获取
 *
 * Usage:
 *
 * # 方法2: 使用环境变量
 * forge script script/SimulateTrading.s.sol --broadcast --rpc-url http://localhost:8545
 */
contract SimulateTrading is Script {
    // ============ 测试账户定义 ============

    // 管理者账户
    uint256 public constant adminPrivateKey =
        0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a;
    address public constant admin = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;

    // 用户账户
    uint256 public constant user1PrivateKey =
        0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356;
    address public constant user1 = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;

    uint256 public constant user2PrivateKey =
        0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97;
    address public constant user2 = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f;

    uint256 public constant user3PrivateKey =
        0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6;
    address public constant user3 = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;

    // ============ 动态获取的合约地址 ============
    // 这些地址将从 DeployAIVault.s.sol 的 getDeployedAddresses 方法动态获取
    address public managerAddress;
    address public vaultFactoryAddress;
    address public usdcTokenAddress;
    address public wethTokenAddress;
    address public usdcVaultAddress;
    address public ethVaultAddress;
    address public aaveAdapterAddress;
    address public uniswapV2AdapterAddress;
    address public uniswapV3AdapterAddress;

    // 部署脚本地址（用于获取合约地址）
    address public deployScriptAddress;

    // ============ 合约实例 ============
    AIAgentVaultManager public manager;
    VaultFactory public vaultFactory;
    MockToken public usdc;
    MockWETH9 public weth;
    VaultImplementation public usdcVault;
    VaultSharesETH public wethVault;
    AaveAdapter public aaveAdapter;
    UniswapV2Adapter public uniswapV2Adapter;
    UniswapV3Adapter public uniswapV3Adapter;

    // 额外的代币（用于测试）
    MockToken public wbtc;
    MockToken public usdt;
    MockToken public dai;

    /**
     * @notice 主执行函数
     * @dev 连接到已部署的合约并执行模拟交易 - 每个用户在自己的广播内完成所有操作
     */
    function run() external {
        console.log(
            "=== Starting Simulated Trading with Deployed Contracts ==="
        );
        console.log("Chain ID:", block.chainid);

        // 1. 获取部署的合约地址
        _getDeployedAddresses();

        // 2. 连接到已部署的合约
        _connectToDeployedContracts();

        // 3. 部署额外的测试代币
        _deployAdditionalTokens();

        // 4. 为所有测试账户提供资金（不需要广播）
        _fundAllAccounts();

        // 5. 每个用户在自己的广播会话内完成所有操作
        _executeAdminOperations();
        _executeUser1Operations();
        _executeUser2Operations();
        _executeUser3Operations();

        // 6. 输出交易结果
        _logTradingResults();

        console.log("=== Simulated Trading Completed ===");
    }

    /**
     * @notice 设置部署脚本地址
     * @param _deployScriptAddress 部署脚本的地址
     */
    function setDeployScriptAddress(address _deployScriptAddress) external {
        deployScriptAddress = _deployScriptAddress;
        console.log("Deploy script address set to:", deployScriptAddress);
    }

    /**
     * @notice 获取部署的合约地址（使用 subgraph.yaml 中的地址）
     */
    function _getDeployedAddresses() internal {
        console.log("\n--- Setting Contract Addresses from Subgraph ---");

        // 使用 deployedContracts.ts 中的地址（正确校验和格式）
        managerAddress = 0x8ce361602B935680E8DeC218b820ff5056BeB7af; // AIAgentVaultManager
        vaultFactoryAddress = 0xe1DA8919f262Ee86f9BE05059C9280142CF23f48; // VaultFactory
        usdcTokenAddress = 0x700b6A60ce7EaaEA56F065753d8dcB9653dbAD35; // MockToken (USDC)
        wethTokenAddress = 0xA15BB66138824a1c7167f5E85b957d04Dd34E468; // MockWETH9
        usdcVaultAddress = 0x36005A8e2295e5186699663a4f4D9CE3Da89Aefa; // VaultImplementation
        ethVaultAddress = 0xf56AA3aCedDf88Ab12E494d0B96DA3C09a5d264e; // VaultSharesETH
        aaveAdapterAddress = 0x33b1B5Aa9Aa4Da83a332F0bC5cAC6A903FDE5d92; // AaveAdapter
        uniswapV2AdapterAddress = 0x19A1c09fE3399C4Daaa2C98b936a8E460fC5Eaa4; // UniswapV2Adapter
        uniswapV3AdapterAddress = 0x49B8E3b089d4ebf9F37B1dA9B839Ec013C2cD8c9; // UniswapV3Adapter
    }

    /**
     * @notice 连接到已部署的合约
     */
    function _connectToDeployedContracts() internal {
        console.log("\n--- Connecting to Deployed Contracts ---");

        // 确保地址已经获取
        require(managerAddress != address(0), "Manager address not set");
        require(
            vaultFactoryAddress != address(0),
            "VaultFactory address not set"
        );
        require(usdcTokenAddress != address(0), "USDC token address not set");
        require(wethTokenAddress != address(0), "WETH token address not set");
        require(usdcVaultAddress != address(0), "USDC vault address not set");
        require(ethVaultAddress != address(0), "ETH vault address not set");
        require(
            aaveAdapterAddress != address(0),
            "Aave adapter address not set"
        );
        require(
            uniswapV2AdapterAddress != address(0),
            "UniswapV2 adapter address not set"
        );
        require(
            uniswapV3AdapterAddress != address(0),
            "UniswapV3 adapter address not set"
        );

        // 连接核心合约
        manager = AIAgentVaultManager(managerAddress);
        vaultFactory = VaultFactory(vaultFactoryAddress);
        usdc = MockToken(usdcTokenAddress);
        weth = MockWETH9(wethTokenAddress);
        usdcVault = VaultImplementation(usdcVaultAddress);
        wethVault = VaultSharesETH(payable(ethVaultAddress));
        aaveAdapter = AaveAdapter(aaveAdapterAddress);
        uniswapV2Adapter = UniswapV2Adapter(uniswapV2AdapterAddress);
        uniswapV3Adapter = UniswapV3Adapter(uniswapV3AdapterAddress);

        console.log("Manager connected at:", address(manager));
        console.log("VaultFactory connected at:", address(vaultFactory));
        console.log("USDC token connected at:", address(usdc));
        console.log("WETH token connected at:", address(weth));
        console.log("USDC vault connected at:", address(usdcVault));
        console.log("WETH vault connected at:", address(wethVault));
        console.log("Aave adapter connected at:", address(aaveAdapter));
        console.log(
            "UniswapV2 adapter connected at:",
            address(uniswapV2Adapter)
        );
        console.log(
            "UniswapV3 adapter connected at:",
            address(uniswapV3Adapter)
        );
    }

    /**
     * @notice 部署额外的测试代币
     */
    function _deployAdditionalTokens() internal {
        console.log("\n--- Deploying Additional Test Tokens ---");

        wbtc = new MockToken("Wrapped Bitcoin", "WBTC");
        usdt = new MockToken("Tether USD", "USDT");
        dai = new MockToken("Dai Stablecoin", "DAI");

        console.log("WBTC deployed at:", address(wbtc));
        console.log("USDT deployed at:", address(usdt));
        console.log("DAI deployed at:", address(dai));
    }

    /**
     * @notice 为所有测试账户提供资金（在admin广播会话内）
     */
    function _fundAllAccounts() internal {
        console.log("\n--- Funding All Test Accounts ---");

        vm.startBroadcast(adminPrivateKey);

        // 为所有测试账户提供代币资金
        usdc.mint(admin, 1000000 * 10 ** 18);
        usdc.mint(user1, 1000000 * 10 ** 18);
        usdc.mint(user2, 1000000 * 10 ** 18);
        usdc.mint(user3, 1000000 * 10 ** 18);

        // 提供额外的测试代币
        wbtc.mint(admin, 1 * 10 ** 18);
        wbtc.mint(user1, 1 * 10 ** 18);
        wbtc.mint(user2, 1 * 10 ** 18);
        wbtc.mint(user3, 1 * 10 ** 18);

        usdt.mint(admin, 10000 * 10 ** 18);
        usdt.mint(user1, 10000 * 10 ** 18);
        usdt.mint(user2, 10000 * 10 ** 18);
        usdt.mint(user3, 10000 * 10 ** 18);

        dai.mint(admin, 10000 * 10 ** 18);
        dai.mint(user1, 10000 * 10 ** 18);
        dai.mint(user2, 10000 * 10 ** 18);
        dai.mint(user3, 10000 * 10 ** 18);

        vm.stopBroadcast();

        // 为测试账户提供额外的ETH用于gas费用和存款（不需要广播）
        vm.deal(admin, 150 ether); // 50 ether for deposit + 100 ether for gas
        vm.deal(user1, 100 ether);
        vm.deal(user2, 110 ether); // 10 ether for deposit + 100 ether for gas
        vm.deal(user3, 100 ether);

        console.log(
            "All test accounts funded with tokens and ETH successfully"
        );
    }

    /**
     * @notice 执行 Admin 的所有操作（在自己的广播会话内）
     */
    function _executeAdminOperations() internal {
        console.log("\n--- Executing Admin Operations ---");

        vm.startBroadcast(adminPrivateKey);

        // 1. 存款操作
        console.log("Admin depositing to vaults...");

        // Admin 存款到 USDC 金库
        usdc.approve(address(usdcVault), 20000 * 10 ** 18);
        usdcVault.deposit(20000 * 10 ** 18, admin);
        console.log("Admin deposited 20,000 USDC to USDC vault");

        // Admin 存款到 WETH 金库
        wethVault.depositETH{value: 50 ether}(admin);
        console.log(
            "Admin deposited 50 ETH to WETH vault (converted to WETH automatically)"
        );

        // 2. 模拟时间过去
        vm.warp(block.timestamp + 1 days);
        console.log("Advanced time by 1 day to simulate interest accrual");

        // 3. 赎回操作
        console.log("Admin redeeming from vaults...");

        // 从 USDC 金库赎回
        uint256 adminUsdcShares = usdcVault.balanceOf(admin);
        if (adminUsdcShares > 0) {
            uint256 redeemUsdcAmount = adminUsdcShares / 20; // 赎回1/20的份额
            usdcVault.redeem(redeemUsdcAmount, admin, admin);
            console.log("Admin redeemed 1/20 of their USDC vault shares");
        }

        // 从 WETH 金库赎回
        uint256 adminWethShares = wethVault.balanceOf(admin);
        if (adminWethShares > 0) {
            uint256 redeemWethAmount = adminWethShares / 20; // 赎回1/20的份额
            wethVault.redeemETH(redeemWethAmount, admin, admin);
            console.log(
                "Admin redeemed 1/20 of their WETH vault shares and received ETH"
            );
        }

        vm.stopBroadcast();
        console.log("Admin operations completed successfully!");
    }

    /**
     * @notice 执行 User1 的所有操作（在自己的广播会话内）
     */
    function _executeUser1Operations() internal {
        console.log("\n--- Executing User1 Operations ---");

        vm.startBroadcast(user1PrivateKey);

        // 1. 存款操作
        console.log("User1 depositing to USDC vault...");
        usdc.approve(address(usdcVault), 10000 * 10 ** 18);
        usdcVault.deposit(10000 * 10 ** 18, user1);
        console.log("User1 deposited 10,000 USDC to USDC vault");

        // 2. 模拟时间过去
        vm.warp(block.timestamp + 1 days);
        console.log("Advanced time by 1 day to simulate interest accrual");

        // 3. 赎回操作
        console.log("User1 redeeming from USDC vault...");
        uint256 user1Shares = usdcVault.balanceOf(user1);
        if (user1Shares > 0) {
            uint256 redeemAmount = user1Shares / 10; // 赎回1/10的份额
            usdcVault.redeem(redeemAmount, user1, user1);
            console.log("User1 redeemed 1/10 of their USDC vault shares");
        }

        vm.stopBroadcast();
        console.log("User1 operations completed successfully!");
    }

    /**
     * @notice 执行 User2 的所有操作（在自己的广播会话内）
     */
    function _executeUser2Operations() internal {
        console.log("\n--- Executing User2 Operations ---");

        vm.startBroadcast(user2PrivateKey);

        // 1. 存款操作
        console.log("User2 depositing to WETH vault...");
        wethVault.depositETH{value: 10 ether}(user2);
        console.log(
            "User2 deposited 10 ETH to WETH vault (converted to WETH automatically)"
        );

        // 2. 模拟时间过去
        vm.warp(block.timestamp + 1 days);
        console.log("Advanced time by 1 day to simulate interest accrual");

        // 3. 赎回操作
        console.log("User2 redeeming from WETH vault...");
        uint256 user2Shares = wethVault.balanceOf(user2);
        if (user2Shares > 0) {
            uint256 redeemAmount = user2Shares / 10; // 赎回1/10的份额
            wethVault.redeemETH(redeemAmount, user2, user2);
            console.log(
                "User2 redeemed 1/10 of their WETH vault shares and received ETH"
            );
        }

        vm.stopBroadcast();
        console.log("User2 operations completed successfully!");
    }

    /**
     * @notice 执行 User3 的所有操作（在自己的广播会话内）
     */
    function _executeUser3Operations() internal {
        console.log("\n--- Executing User3 Operations ---");

        vm.startBroadcast(user3PrivateKey);

        // 1. 存款操作
        console.log("User3 depositing to USDC vault...");
        usdc.approve(address(usdcVault), 5000 * 10 ** 18);
        usdcVault.deposit(5000 * 10 ** 18, user3);
        console.log("User3 deposited 5,000 USDC to USDC vault");

        // 2. 模拟时间过去
        vm.warp(block.timestamp + 1 days);
        console.log("Advanced time by 1 day to simulate interest accrual");

        // 3. 赎回操作
        console.log("User3 redeeming from USDC vault...");
        uint256 user3Shares = usdcVault.balanceOf(user3);
        if (user3Shares > 0) {
            uint256 redeemAmount = user3Shares / 10; // 赎回1/10的份额
            usdcVault.redeem(redeemAmount, user3, user3);
            console.log("User3 redeemed 1/10 of their USDC vault shares");
        }

        vm.stopBroadcast();
        console.log("User3 operations completed successfully!");
    }

    /**
     * @notice 输出交易结果和最终状态
     */
    function _logTradingResults() internal view {
        console.log("\n=== Trading Results Summary ===");
        console.log("USDC vault address:", address(usdcVault));
        console.log("WETH vault address:", address(wethVault));
        console.log("Manager address:", address(manager));

        console.log("\n=== Test Accounts ===");
        console.log("Admin:", admin);
        console.log("User1:", user1);
        console.log("User2:", user2);
        console.log("User3:", user3);

        // 显示最终金库余额
        uint256 finalUsdcVaultBalance = usdc.balanceOf(address(usdcVault));
        uint256 finalWethVaultBalance = weth.balanceOf(address(wethVault));

        console.log("\n=== Final Vault Status ===");
        console.log(
            "Final USDC vault balance:",
            finalUsdcVaultBalance / 10 ** 18
        );
        console.log(
            "Final WETH vault balance:",
            finalWethVaultBalance / 10 ** 18
        );

        // 显示金库份额信息
        console.log("\n=== Final Vault Shares Summary ===");
        console.log("USDC Vault:");
        console.log("  User1 shares:", usdcVault.balanceOf(user1) / 10 ** 18);
        console.log("  User3 shares:", usdcVault.balanceOf(user3) / 10 ** 18);
        console.log("  Admin shares:", usdcVault.balanceOf(admin) / 10 ** 18);

        console.log("WETH Vault:");
        console.log("  User2 shares:", wethVault.balanceOf(user2) / 10 ** 18);
        console.log("  Admin shares:", wethVault.balanceOf(admin) / 10 ** 18);

        console.log("\n=== Usage Instructions ===");
        console.log(
            "1. Each user executed their operations in their own broadcast session"
        );
        console.log(
            "2. All users completed deposits and redemptions successfully"
        );
        console.log("3. Time has been advanced to simulate interest accrual");
        console.log("4. Check subgraph for transaction data");
    }
}
