//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./DeployHelpers.s.sol";
import "../contracts/protocol/AIAgentVaultManager.sol";
import "../contracts/protocol/VaultShares.sol";
import "../contracts/protocol/investableUniverseAdapters/AaveAdapter.sol";
import "../contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol";
import "../contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol";
import "../test/mock/MockToken.sol";
import "../test/mock/MockAavePool.sol";
import "../test/mock/MockUniswapV2.sol";
import "../test/mock/RealisticUniswapV3.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DeploySimulatedTrading
 * @notice 部署简化的模拟交易环境，包含管理者和用户账户
 * @dev 创建本地测试环境，用于前端测试
 *
 * 测试账户：
 * - 1个管理者账户
 * - 3个用户账户
 *
 * Usage:
 * yarn deploy --file DeploySimulatedTrading.s.sol  # 部署到本地 anvil 链
 */
contract DeploySimulatedTrading is ScaffoldETHDeploy {
    // ============ 测试账户定义 ============

    // 管理者账户
    uint256 public constant adminPrivateKey = 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a;
    address public constant admin = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;

    // 用户账户
    uint256 public constant user1PrivateKey = 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356;
    address public constant user1 = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;

    uint256 public constant user2PrivateKey = 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97;
    address public constant user2 = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f;

    uint256 public constant user3PrivateKey = 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6;
    address public constant user3 = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;

    // ============ 核心合约 ============
    AIAgentVaultManager public manager;
    MockToken public usdc;
    MockToken public weth;
    MockToken public wbtc;
    MockToken public usdt;
    MockToken public dai;

    // ============ 金库合约 ============
    address public usdcVault;
    address public wethVault;
    address public wbtcVault;

    // ============ 适配器合约 ============
    AaveAdapter public aaveAdapter;
    UniswapV2Adapter public uniswapV2Adapter;
    UniswapV3Adapter public uniswapV3Adapter;

    // ============ Mock协议合约 ============
    MockAavePool public mockAavePool;
    MockUniswapV2Factory public mockUniswapV2Factory;
    MockUniswapV2Router public mockUniswapV2Router;
    RealisticUniswapV3Factory public realisticUniswapV3Factory;
    RealisticSwapRouter public realisticUniswapV3Router;
    RealisticNonfungiblePositionManager public realisticPositionManager;
    RealisticQuoter public realisticQuoter;

    /**
     * @notice 主部署函数
     * @dev 部署所有合约并配置模拟交易环境
     */
    function run() external ScaffoldEthDeployerRunner {
        console.log("=== Starting Simulated Trading Environment Deployment ===");
        console.log("Deployer address:", deployer);
        console.log("Chain ID:", block.chainid);

        // 1. 部署代币合约
        _deployTokens();

        // 2. 部署管理器
        _deployManager();

        // 3. 部署Mock协议合约
        _deployMockProtocols();

        // 4. 部署适配器
        _deployAdapters();

        // 5. 创建金库
        _createVaults();

        // 6. 配置系统
        _configureSystem();

        // 7. 为测试账户提供资金
        _fundTestAccounts();

        // 8. 模拟用户交易
        _simulateUserTrading();

        // 9. 输出部署信息
        _logDeploymentInfo();

        console.log("=== Simulated Trading Environment Deployment Completed ===");
    }

    /**
     * @notice 部署代币合约
     */
    function _deployTokens() internal {
        console.log("\n--- Deploying Token Contracts ---");

        usdc = new MockToken("USD Coin", "USDC");
        weth = new MockToken("Wrapped Ether", "WETH");
        wbtc = new MockToken("Wrapped Bitcoin", "WBTC");
        usdt = new MockToken("Tether USD", "USDT");
        dai = new MockToken("Dai Stablecoin", "DAI");

        console.log("USDC deployed at:", address(usdc));
        console.log("WETH deployed at:", address(weth));
        console.log("WBTC deployed at:", address(wbtc));
        console.log("USDT deployed at:", address(usdt));
        console.log("DAI deployed at:", address(dai));

        // 为部署者铸造大量代币用于测试
        usdc.mint(deployer, 10000000 * 10 ** 18); // 1000万 USDC
        weth.mint(deployer, 100000 * 10 ** 18); // 10万 WETH
        wbtc.mint(deployer, 1000 * 10 ** 18); // 1000 WBTC
        usdt.mint(deployer, 10000000 * 10 ** 18); // 1000万 USDT
        dai.mint(deployer, 10000000 * 10 ** 18); // 1000万 DAI

        console.log("Deployer balances:");
        console.log("USDC:", usdc.balanceOf(deployer) / 10 ** 18);
        console.log("WETH:", weth.balanceOf(deployer) / 10 ** 18);
        console.log("WBTC:", wbtc.balanceOf(deployer) / 10 ** 18);
        console.log("USDT:", usdt.balanceOf(deployer) / 10 ** 18);
        console.log("DAI:", dai.balanceOf(deployer) / 10 ** 18);
    }

    /**
     * @notice 部署管理器合约
     */
    function _deployManager() internal {
        console.log("\n--- Deploying Manager Contract ---");

        manager = new AIAgentVaultManager();
        console.log("Manager deployed at:", address(manager));
        deployments.push(Deployment("AIAgentVaultManager", address(manager)));
    }

    /**
     * @notice 部署Mock协议合约
     */
    function _deployMockProtocols() internal {
        console.log("\n--- Deploying Mock Protocol Contracts ---");

        // Aave Mock
        mockAavePool = new MockAavePool();
        console.log("MockAavePool deployed at:", address(mockAavePool));

        // 为MockAavePool铸造代币用于赎回
        usdc.mint(address(mockAavePool), 10000000 * 10 ** 18);
        weth.mint(address(mockAavePool), 100000 * 10 ** 18);
        wbtc.mint(address(mockAavePool), 1000 * 10 ** 18);
        usdt.mint(address(mockAavePool), 10000000 * 10 ** 18);
        dai.mint(address(mockAavePool), 10000000 * 10 ** 18);

        // UniswapV2 Mock
        mockUniswapV2Factory = new MockUniswapV2Factory();
        mockUniswapV2Router = new MockUniswapV2Router(address(mockUniswapV2Factory));
        console.log("MockUniswapV2Factory deployed at:", address(mockUniswapV2Factory));
        console.log("MockUniswapV2Router deployed at:", address(mockUniswapV2Router));

        // 创建多个UniswapV2配对
        address usdcWethPair = mockUniswapV2Factory.createPair(address(usdc), address(weth));
        address wbtcUsdcPair = mockUniswapV2Factory.createPair(address(wbtc), address(usdc));
        address usdtUsdcPair = mockUniswapV2Factory.createPair(address(usdt), address(usdc));
        address daiUsdcPair = mockUniswapV2Factory.createPair(address(dai), address(usdc));

        console.log("USDC/WETH pair:", usdcWethPair);
        console.log("WBTC/USDC pair:", wbtcUsdcPair);
        console.log("USDT/USDC pair:", usdtUsdcPair);
        console.log("DAI/USDC pair:", daiUsdcPair);

        // 为所有配对添加流动性
        _addLiquidityToPair(usdcWethPair);
        _addLiquidityToPair(wbtcUsdcPair);
        _addLiquidityToPair(usdtUsdcPair);
        _addLiquidityToPair(daiUsdcPair);

        // UniswapV3 Mock
        realisticUniswapV3Factory = new RealisticUniswapV3Factory();

        // 创建多个UniswapV3池子
        address usdcWethPool = realisticUniswapV3Factory.createPool(address(usdc), address(weth), 3000);
        address wbtcUsdcPool = realisticUniswapV3Factory.createPool(address(wbtc), address(usdc), 3000);
        address usdtUsdcPool = realisticUniswapV3Factory.createPool(address(usdt), address(usdc), 500);
        address daiUsdcPool = realisticUniswapV3Factory.createPool(address(dai), address(usdc), 500);

        console.log("RealisticUniswapV3Factory deployed at:", address(realisticUniswapV3Factory));
        console.log("USDC/WETH pool:", usdcWethPool);
        console.log("WBTC/USDC pool:", wbtcUsdcPool);
        console.log("USDT/USDC pool:", usdtUsdcPool);
        console.log("DAI/USDC pool:", daiUsdcPool);

        // 为所有池子添加流动性
        _addLiquidityToPool(usdcWethPool);
        _addLiquidityToPool(wbtcUsdcPool);
        _addLiquidityToPool(usdtUsdcPool);
        _addLiquidityToPool(daiUsdcPool);

        realisticUniswapV3Router = new RealisticSwapRouter(usdcWethPool);
        realisticPositionManager = new RealisticNonfungiblePositionManager();
        realisticQuoter = new RealisticQuoter(usdcWethPool);

        realisticPositionManager.setFactory(address(realisticUniswapV3Factory));

        // 为PositionManager铸造代币用于赎回
        usdc.mint(address(realisticPositionManager), 10000000 * 10 ** 18);
        weth.mint(address(realisticPositionManager), 100000 * 10 ** 18);
        wbtc.mint(address(realisticPositionManager), 1000 * 10 ** 18);
        usdt.mint(address(realisticPositionManager), 10000000 * 10 ** 18);
        dai.mint(address(realisticPositionManager), 10000000 * 10 ** 18);

        console.log("RealisticSwapRouter deployed at:", address(realisticUniswapV3Router));
        console.log("RealisticPositionManager deployed at:", address(realisticPositionManager));
        console.log("RealisticQuoter deployed at:", address(realisticQuoter));
    }

    /**
     * @notice 为池子添加流动性
     */
    function _addLiquidityToPool(address pool) internal {
        uint256 liquidityAmount = 100000 * 10 ** 18; // 10万代币

        // 为所有池子添加USDC和WETH流动性
        usdc.mint(pool, liquidityAmount);
        weth.mint(pool, liquidityAmount);

        console.log("Liquidity added to pool");
    }

    /**
     * @notice 为UniswapV2配对添加流动性
     */
    function _addLiquidityToPair(address pairAddress) internal {
        uint256 liquidityAmount = 100000 * 10 ** 18; // 10万代币

        // 为配对添加USDC和WETH流动性
        usdc.mint(pairAddress, liquidityAmount);
        weth.mint(pairAddress, liquidityAmount);

        // 调用配对的mint函数来添加流动性
        MockUniswapV2Pair(pairAddress).mint(deployer);
        console.log("Liquidity added to UniswapV2 pair");
    }

    /**
     * @notice 部署适配器合约
     */
    function _deployAdapters() internal {
        console.log("\n--- Deploying Adapter Contracts ---");

        // 部署Aave适配器
        aaveAdapter = new AaveAdapter(address(mockAavePool));
        console.log("AaveAdapter deployed at:", address(aaveAdapter));
        deployments.push(Deployment("AaveAdapter", address(aaveAdapter)));

        // 部署UniswapV2适配器
        uniswapV2Adapter = new UniswapV2Adapter(address(mockUniswapV2Router));
        console.log("UniswapV2Adapter deployed at:", address(uniswapV2Adapter));
        deployments.push(Deployment("UniswapV2Adapter", address(uniswapV2Adapter)));

        // 部署UniswapV3适配器
        uniswapV3Adapter = new UniswapV3Adapter(
            address(realisticUniswapV3Router),
            address(realisticPositionManager),
            address(realisticUniswapV3Factory),
            address(realisticQuoter)
        );
        console.log("UniswapV3Adapter deployed at:", address(uniswapV3Adapter));
        deployments.push(Deployment("UniswapV3Adapter", address(uniswapV3Adapter)));
    }

    /**
     * @notice 创建金库
     */
    function _createVaults() internal {
        console.log("\n--- Creating Vaults ---");

        // 创建USDC金库
        VaultShares usdcVaultContract = new VaultShares(
            IVaultShares.ConstructorData({
                asset: usdc,
                Fee: 1000, // 0.1% 费用
                vaultName: "AI Vault USDC",
                vaultSymbol: "aiUSDC"
            })
        );
        usdcVault = address(usdcVaultContract);
        console.log("USDC vault address:", usdcVault);
        deployments.push(Deployment("USDCVault", usdcVault));

        usdcVaultContract.transferOwnership(address(manager));
        manager.addVault(usdc, usdcVault);

        // 创建WETH金库
        VaultShares wethVaultContract = new VaultShares(
            IVaultShares.ConstructorData({
                asset: weth,
                Fee: 1000, // 0.1% 费用
                vaultName: "AI Vault WETH",
                vaultSymbol: "aiWETH"
            })
        );
        wethVault = address(wethVaultContract);
        console.log("WETH vault address:", wethVault);
        deployments.push(Deployment("WETHVault", wethVault));

        wethVaultContract.transferOwnership(address(manager));
        manager.addVault(weth, wethVault);

        // 创建WBTC金库
        VaultShares wbtcVaultContract = new VaultShares(
            IVaultShares.ConstructorData({
                asset: wbtc,
                Fee: 1000, // 0.1% 费用
                vaultName: "AI Vault WBTC",
                vaultSymbol: "aiWBTC"
            })
        );
        wbtcVault = address(wbtcVaultContract);
        console.log("WBTC vault address:", wbtcVault);
        deployments.push(Deployment("WBTCVault", wbtcVault));

        wbtcVaultContract.transferOwnership(address(manager));
        manager.addVault(wbtc, wbtcVault);
    }

    /**
     * @notice 配置系统
     */
    function _configureSystem() internal {
        console.log("\n--- Configuring System ---");

        // 1. 添加适配器到管理器
        manager.addAdapter(IProtocolAdapter(address(aaveAdapter)));
        manager.addAdapter(IProtocolAdapter(address(uniswapV2Adapter)));
        manager.addAdapter(IProtocolAdapter(address(uniswapV3Adapter)));
        console.log("All adapters added to manager");

        // 2. 配置Aave适配器 - 支持所有代币
        mockAavePool.createAToken(address(usdc));
        mockAavePool.createAToken(address(weth));
        mockAavePool.createAToken(address(wbtc));
        mockAavePool.createAToken(address(usdt));
        mockAavePool.createAToken(address(dai));

        mockAavePool.setReserveNormalizedIncome(address(usdc), 1e27);
        mockAavePool.setReserveNormalizedIncome(address(weth), 1e27);
        mockAavePool.setReserveNormalizedIncome(address(wbtc), 1e27);
        mockAavePool.setReserveNormalizedIncome(address(usdt), 1e27);
        mockAavePool.setReserveNormalizedIncome(address(dai), 1e27);

        aaveAdapter.setTokenVault(IERC20(address(usdc)), usdcVault);
        aaveAdapter.setTokenVault(IERC20(address(weth)), wethVault);
        aaveAdapter.setTokenVault(IERC20(address(wbtc)), wbtcVault);
        console.log("Aave adapter configured for all tokens");

        // 3. 配置UniswapV2适配器 - 支持多个配对
        uniswapV2Adapter.setTokenConfig(
            IERC20(address(usdc)),
            100, // 1% slippage
            IERC20(address(weth)),
            usdcVault
        );
        console.log("UniswapV2 adapter configured");

        // 4. 配置UniswapV3适配器 - 支持多个池子
        uniswapV3Adapter.setTokenConfig(
            IERC20(address(usdc)),
            IERC20(address(weth)),
            100, // 1% slippage
            3000, // 0.3% fee tier
            -600, // tick lower
            600, // tick upper
            usdcVault
        );
        console.log("UniswapV3 adapter configured");

        // 5. 设置初始资产分配
        uint256[] memory adapterIndices = new uint256[](3);
        adapterIndices[0] = 0; // Aave
        adapterIndices[1] = 1; // UniswapV2
        adapterIndices[2] = 2; // UniswapV3

        uint256[] memory allocationData = new uint256[](3);
        allocationData[0] = 500; // 50% to Aave
        allocationData[1] = 300; // 30% to UniswapV2
        allocationData[2] = 200; // 20% to UniswapV3

        // 为所有代币设置资产分配
        manager.updateHoldingAllocation(usdc, adapterIndices, allocationData);
        manager.updateHoldingAllocation(weth, adapterIndices, allocationData);
        manager.updateHoldingAllocation(wbtc, adapterIndices, allocationData);

        console.log("Initial asset allocation set for all tokens: Aave 50%, UniswapV2 30%, UniswapV3 20%");
    }

    /**
     * @notice 为测试账户提供资金
     */
    function _fundTestAccounts() internal {
        console.log("\n--- Funding Test Accounts ---");

        // 为所有测试账户提供资金
        _fundAccount(admin, "Admin", 100000 * 10 ** 18, 100 * 10 ** 18);
        _fundAccount(user1, "User1", 50000 * 10 ** 18, 50 * 10 ** 18);
        _fundAccount(user2, "User2", 50000 * 10 ** 18, 50 * 10 ** 18);
        _fundAccount(user3, "User3", 50000 * 10 ** 18, 50 * 10 ** 18);

        console.log("All test accounts funded successfully");
    }

    /**
     * @notice 为单个账户提供资金
     */
    function _fundAccount(address account, string memory role, uint256 usdcAmount, uint256 wethAmount) internal {
        usdc.mint(account, usdcAmount);
        weth.mint(account, wethAmount);

        console.log("%s funded with %d USDC and %d WETH", role, usdcAmount / 10 ** 18, wethAmount / 10 ** 18);
    }

    /**
     * @notice 为UniswapV2配对添加初始流动性
     */
    function _addInitialLiquidityToPair(address pairAddress) internal {
        uint256 liquidityAmount = 100000 * 10 ** 18; // 10万代币
        usdc.mint(address(this), liquidityAmount);
        weth.mint(address(this), liquidityAmount);

        usdc.transfer(pairAddress, liquidityAmount);
        weth.transfer(pairAddress, liquidityAmount);

        MockUniswapV2Pair(pairAddress).mint(address(this));
        console.log("Initial liquidity added to UniswapV2 pair");
    }

    /**
     * @notice 输出部署信息
     */
    function _logDeploymentInfo() internal view {
        console.log("\n=== Deployment Summary ===");
        console.log("Manager address:", address(manager));
        console.log("USDC token address:", address(usdc));
        console.log("WETH token address:", address(weth));
        console.log("USDC vault address:", usdcVault);
        console.log("Aave adapter address:", address(aaveAdapter));
        console.log("UniswapV2 adapter address:", address(uniswapV2Adapter));
        console.log("UniswapV3 adapter address:", address(uniswapV3Adapter));

        console.log("\n=== Test Accounts ===");
        console.log("Admin:", admin);
        console.log("User1:", user1);
        console.log("User2:", user2);
        console.log("User3:", user3);

        console.log("\n=== Usage Instructions ===");
        console.log("1. Use the test accounts to interact with the vault");
        console.log("2. All accounts have been funded with USDC and WETH");
        console.log("3. Vault is configured with Aave, UniswapV2, and UniswapV3 adapters");
        console.log("4. Check subgraph for transaction data");
    }

    /**
     * @notice 模拟用户交易
     * @dev 模拟用户存款、投资和赎回操作
     */
    function _simulateUserTrading() internal {
        console.log("\n--- Simulating User Trading ---");

        // 模拟用户1存款到USDC金库
        _simulateUserDeposit(user1, usdc, usdcVault, 10000 * 10 ** 18, "User1 USDC deposit");

        // 模拟用户2存款到WETH金库
        _simulateUserDeposit(user2, weth, wethVault, 50 * 10 ** 18, "User2 WETH deposit");

        // 模拟用户3存款到WBTC金库
        _simulateUserDeposit(user3, wbtc, wbtcVault, 5 * 10 ** 18, "User3 WBTC deposit");

        // 等待一些区块，让投资有时间执行
        vm.roll(block.number + 5);

        // 模拟用户1再次存款
        _simulateUserDeposit(user1, usdc, usdcVault, 5000 * 10 ** 18, "User1 additional USDC deposit");

        // 模拟用户2赎回部分份额
        _simulateUserRedeem(user2, wethVault, 25 * 10 ** 18, "User2 partial WETH redeem");

        // 检查金库状态
        _checkVaultStatus(usdcVault, "USDC");
        _checkVaultStatus(wethVault, "WETH");
        _checkVaultStatus(wbtcVault, "WBTC");

        console.log("User trading simulation completed");
    }

    /**
     * @notice 模拟用户存款
     */
    function _simulateUserDeposit(
        address user,
        MockToken token,
        address vault,
        uint256 amount,
        string memory description
    ) internal {
        // 检查用户余额
        uint256 userBalance = token.balanceOf(user);
        console.log("User %s balance: %d", description, userBalance / 10 ** 18);

        if (userBalance >= amount) {
            // 授权金库使用代币
            token.approve(vault, amount);

            // 执行存款
            VaultShares(vault).deposit(amount, user);

            console.log("SUCCESS %s: %d tokens deposited", description, amount / 10 ** 18);
        } else {
            console.log("FAILED %s: Insufficient balance", description);
        }
    }

    /**
     * @notice 模拟用户赎回
     */
    function _simulateUserRedeem(address user, address vault, uint256 shares, string memory description) internal {
        // 检查用户份额
        uint256 userShares = VaultShares(vault).balanceOf(user);
        console.log("User %s shares: %d", description, userShares / 10 ** 18);

        if (userShares >= shares) {
            // 执行赎回
            VaultShares(vault).redeem(shares, user, user);

            console.log("SUCCESS %s: %d shares redeemed", description, shares / 10 ** 18);
        } else {
            console.log("FAILED %s: Insufficient shares", description);
        }
    }

    /**
     * @notice 检查金库状态
     */
    function _checkVaultStatus(address vault, string memory vaultName) internal view {
        VaultShares vaultContract = VaultShares(vault);
        console.log("\n--- %s Vault Status ---", vaultName);
        console.log("Total Assets: %d", vaultContract.totalAssets() / 10 ** 18);
        console.log("Total Supply: %d", vaultContract.totalSupply() / 10 ** 18);
        console.log("Vault Address: %s", vault);
    }
}
