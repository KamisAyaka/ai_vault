// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../contracts/protocol/AIAgentVaultManager.sol";
import "../../contracts/protocol/VaultFactory.sol";
import "../../contracts/protocol/VaultImplementation.sol";
import "../../contracts/protocol/VaultSharesETH.sol";
import "../../contracts/protocol/investableUniverseAdapters/AaveAdapter.sol";
import "../../contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol";
import "../../contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol";
import "../../contracts/vendor/UniswapV3/core/IMinimalUniswapV3Pool.sol";
import "../../contracts/vendor/UniswapV3/core/IMinimalUniswapV3Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title RealNetworkForkTest
 * @notice 真实网络 Fork 测试
 * 测试在真实网络状态下的协议集成，使用真实的合约地址和代币
 */
contract RealNetworkForkTest is Test {
    // 网络配置
    uint256 public mainnetFork;

    // 核心合约
    AIAgentVaultManager public manager;
    VaultFactory public vaultFactory;
    VaultImplementation public vaultImplementation;
    address public owner;
    address public user;

    // 真实适配器
    AaveAdapter public aaveAdapter;
    UniswapV2Adapter public uniswapV2Adapter;
    UniswapV3Adapter public uniswapV3Adapter;

    // 真实代币地址 (Mainnet)
    address public constant USDC_MAINNET = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant WBTC_MAINNET = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant USDT_MAINNET = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // 真实协议地址 (Mainnet)
    address public constant AAVE_POOL_MAINNET = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public constant UNISWAP_V2_ROUTER_MAINNET = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant UNISWAP_V2_FACTORY_MAINNET = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant UNISWAP_V3_ROUTER_MAINNET = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address public constant UNISWAP_V3_POSITION_MANAGER_MAINNET = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address public constant UNISWAP_V3_FACTORY_MAINNET = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    // 金库地址
    address payable public vaultAddress;
    VaultSharesETH public ethVault;

    // 事件
    event ForkTestStarted(string network, uint256 blockNumber);
    event AdapterDeployed(string adapterName, address adapterAddress);
    event VaultCreated(address vaultAddress);
    event ETHVaultCreated(address ethVaultAddress);
    event InvestmentTested(string protocol, uint256 amount, bool success);
    event TestCompleted(string testName, bool success);

    function setUp() public {
        // 设置测试账户
        owner = address(this);
        user = address(0x123);

        // 创建 mainnet fork
        mainnetFork = vm.createFork("mainnet");

        console.log("=== Real Network Fork Test Setup ===");
        console.log("Mainnet fork ID:", mainnetFork);
    }

    /**
     * @notice 测试 Mainnet 网络上的完整集成
     */
    function testMainnetIntegration() public {
        vm.selectFork(mainnetFork);
        console.log("Testing on Mainnet fork at block:", block.number);
        emit ForkTestStarted("mainnet", block.number);

        // 部署管理器
        _deployManager();

        // 部署真实适配器
        _deployRealAdapters();

        // 创建金库
        _createVault();

        // 配置适配器
        _configureAdapters();

        // 添加适配器到管理器
        _addAdaptersToManager();

        // 测试基本集成 - 只验证合约部署和配置
        console.log("Basic integration test completed - all contracts deployed and configured");

        // 验证金库创建成功
        assertNotEq(vaultAddress, address(0), "Vault should be created");

        // 验证适配器添加成功
        assertEq(manager.getAllAdapters().length, 3, "Should have 3 adapters");

        console.log("All basic integration checks passed");

        emit TestCompleted("Mainnet Integration", true);
        console.log("=== Mainnet Integration Test Completed Successfully ===");
    }

    /**
     * @notice 测试 Aave 协议集成
     */
    function testAaveProtocolIntegration() public {
        vm.selectFork(mainnetFork);
        console.log("=== Testing Aave Protocol Integration ===");

        _deployManager();
        aaveAdapter = new AaveAdapter(AAVE_POOL_MAINNET);
        emit AdapterDeployed("Aave", address(aaveAdapter));

        _createVault();

        // 配置 Aave 适配器
        aaveAdapter.setTokenVault(IERC20(USDC_MAINNET), vaultAddress);

        // 给金库一些 USDC 进行测试
        _fundVaultWithToken(USDC_MAINNET, 1000 * 1e6); // 1000 USDC

        // 测试投资
        vm.prank(vaultAddress);
        IERC20(USDC_MAINNET).approve(address(aaveAdapter), 1000 * 1e6);
        vm.prank(vaultAddress);
        aaveAdapter.invest(IERC20(USDC_MAINNET), 1000 * 1e6);

        // 验证投资
        uint256 totalValue = aaveAdapter.getTotalValue(IERC20(USDC_MAINNET));
        assertGt(totalValue, 0, "Aave investment should have value");
        console.log("Aave total value:", totalValue);

        emit InvestmentTested("Aave", 1000 * 1e6, true);
    }

    /**
     * @notice 测试 UniswapV2 协议集成
     */
    function testUniswapV2ProtocolIntegration() public {
        vm.selectFork(mainnetFork);
        console.log("=== Testing UniswapV2 Protocol Integration ===");

        _deployManager();
        uniswapV2Adapter = new UniswapV2Adapter(UNISWAP_V2_ROUTER_MAINNET, UNISWAP_V2_FACTORY_MAINNET);
        emit AdapterDeployed("UniswapV2", address(uniswapV2Adapter));

        _createVault();

        // 配置 UniswapV2 适配器
        uniswapV2Adapter.setTokenConfig(
            IERC20(USDC_MAINNET),
            100, // 1% slippage
            IERC20(WETH_MAINNET),
            vaultAddress
        );

        // 给金库一些 USDC 进行测试
        _fundVaultWithToken(USDC_MAINNET, 1000 * 1e6); // 1000 USDC

        // 测试投资
        vm.prank(vaultAddress);
        IERC20(USDC_MAINNET).approve(address(uniswapV2Adapter), 1000 * 1e6);
        vm.prank(vaultAddress);
        uniswapV2Adapter.invest(IERC20(USDC_MAINNET), 1000 * 1e6);

        // 验证投资
        uint256 totalValue = uniswapV2Adapter.getTotalValue(IERC20(USDC_MAINNET));
        assertGt(totalValue, 0, "UniswapV2 investment should have value");
        console.log("UniswapV2 total value:", totalValue);

        emit InvestmentTested("UniswapV2", 1000 * 1e6, true);
    }

    /**
     * @notice 测试 UniswapV3 协议集成 (WBTC/USDC 池子) - 智能价格范围
     */
    function testUniswapV3WBTCSmartRangeIntegration() public {
        vm.selectFork(mainnetFork);
        console.log("=== Testing UniswapV3 WBTC/USDC Smart Range Integration ===");

        _deployManager();
        uniswapV3Adapter = new UniswapV3Adapter(
            UNISWAP_V3_ROUTER_MAINNET, UNISWAP_V3_POSITION_MANAGER_MAINNET, UNISWAP_V3_FACTORY_MAINNET
        );
        emit AdapterDeployed("UniswapV3", address(uniswapV3Adapter));

        _createVault();

        // 先查询当前池子的价格信息
        address poolAddress =
            IMinimalUniswapV3Factory(UNISWAP_V3_FACTORY_MAINNET).getPool(WBTC_MAINNET, USDC_MAINNET, 3000);
        require(poolAddress != address(0), "Pool does not exist");
        console.log("Pool address:", poolAddress);

        (uint160 sqrtPriceX96, int24 currentTick,,,,,) = IMinimalUniswapV3Pool(poolAddress).slot0();
        console.log("Current pool sqrtPriceX96:", sqrtPriceX96);
        console.log("Current pool tick:", currentTick);

        // 计算当前价格 (简化计算)
        uint256 currentPrice = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96)) >> 96;
        console.log("Current price (simplified):", currentPrice);

        // 计算合理的 tick 范围
        // 在 UniswapV3 中，每个 tick 代表 0.01% 的价格变化
        // 对于 WBTC/USDC 这种高价值代币对，我们需要更小的范围
        int24 tickRange = 2000; // 大约 20% 的范围 (2000 ticks = 20%)
        int24 tickLower = currentTick - tickRange;
        int24 tickUpper = currentTick + tickRange;

        // 确保 tick 对齐到 fee tier 的倍数
        // 对于 0.3% fee tier，tick 必须是 60 的倍数
        tickLower = (tickLower / 60) * 60;
        tickUpper = (tickUpper / 60) * 60;

        // 确保 tick 范围仍然有效
        if (tickLower >= tickUpper) {
            tickLower = tickUpper - 60;
        }

        console.log("Calculated tick range:");
        console.logInt(tickLower);
        console.log("to");
        console.logInt(tickUpper);

        // 验证 tick 范围是否有效
        require(tickLower < tickUpper, "Invalid tick range: lower >= upper");
        require(tickLower >= -887220, "Tick lower too low");
        require(tickUpper <= 887220, "Tick upper too high");

        // 确保当前价格在范围内
        require(currentTick >= tickLower && currentTick <= tickUpper, "Current price outside range");

        // 配置 UniswapV3 适配器 - 使用智能计算的 tick 范围
        uniswapV3Adapter.setTokenConfig(
            IERC20(WBTC_MAINNET), // 使用 WBTC 作为主代币
            IERC20(USDC_MAINNET), // 使用 USDC 作为配对代币
            1000, // 10% slippage
            3000, // 0.3% fee tier
            tickLower, // 基于当前价格的 -5% 范围
            tickUpper, // 基于当前价格的 +5% 范围
            vaultAddress
        );

        // 给金库一些 WBTC 和 USDC 进行测试
        _fundVaultWithToken(WBTC_MAINNET, 1 * 1e8); // 1 WBTC (8 decimals)
        _fundVaultWithToken(USDC_MAINNET, 100000 * 1e6); // 100,000 USDC

        // 检查金库余额
        uint256 wbtcBalance = IERC20(WBTC_MAINNET).balanceOf(vaultAddress);
        uint256 usdcBalance = IERC20(USDC_MAINNET).balanceOf(vaultAddress);
        console.log("Vault WBTC balance before investment:", wbtcBalance);
        console.log("Vault USDC balance before investment:", usdcBalance);

        // 测试投资
        vm.prank(vaultAddress);
        IERC20(WBTC_MAINNET).approve(address(uniswapV3Adapter), 1 * 1e8);
        vm.prank(vaultAddress);
        IERC20(USDC_MAINNET).approve(address(uniswapV3Adapter), 100000 * 1e6);

        console.log("Starting investment...");
        vm.prank(vaultAddress);
        uint256 investedAmount = uniswapV3Adapter.invest(IERC20(WBTC_MAINNET), 1 * 1e8);
        console.log("Investment completed, invested amount:", investedAmount);

        // 验证投资
        uint256 totalValue = uniswapV3Adapter.getTotalValue(IERC20(WBTC_MAINNET));
        assertGt(totalValue, 0, "UniswapV3 WBTC investment should have value");
        console.log("UniswapV3 WBTC total value:", totalValue);

        emit InvestmentTested("UniswapV3-WBTC-Smart", 1 * 1e8, true);
    }

    /**
     * @notice 测试 UniswapV3 协议集成 (USDC/WETH 池子)
     */
    function testUniswapV3ProtocolIntegration() public {
        vm.selectFork(mainnetFork);
        console.log("=== Testing UniswapV3 Protocol Integration ===");

        _deployManager();
        uniswapV3Adapter = new UniswapV3Adapter(
            UNISWAP_V3_ROUTER_MAINNET, UNISWAP_V3_POSITION_MANAGER_MAINNET, UNISWAP_V3_FACTORY_MAINNET
        );
        emit AdapterDeployed("UniswapV3", address(uniswapV3Adapter));

        _createVault();

        // 先查询当前池子的价格信息
        address poolAddress =
            IMinimalUniswapV3Factory(UNISWAP_V3_FACTORY_MAINNET).getPool(USDC_MAINNET, WETH_MAINNET, 3000);
        require(poolAddress != address(0), "Pool does not exist");

        (, int24 currentTick,,,,,) = IMinimalUniswapV3Pool(poolAddress).slot0();

        // 首先将当前tick对齐到60的倍数
        int24 alignedCurrentTick = (currentTick / 60) * 60;

        // 使用更宽的tick范围以确保流动性充足
        int24 tickRange = 10000; // 大约 100% 的范围，确保有足够的流动性空间
        int24 tickLower = alignedCurrentTick - tickRange;
        int24 tickUpper = alignedCurrentTick + tickRange;

        // 确保 tick 对齐到 fee tier 的倍数
        // 对于 0.3% fee tier，tick 必须是 60 的倍数
        tickLower = (tickLower / 60) * 60;
        tickUpper = (tickUpper / 60) * 60;

        // 确保 tick 范围仍然有效
        if (tickLower >= tickUpper) {
            tickLower = tickUpper - 60;
        }

        // 确保tick范围不会超出UniswapV3的限制
        if (tickLower < -887200) {
            tickLower = -887200;
        }
        if (tickUpper > 887200) {
            tickUpper = 887200;
        }

        console.log("Current tick:", currentTick);
        console.log("Aligned current tick:", alignedCurrentTick);
        console.log("Tick range:");
        console.logInt(tickLower);
        console.log("to");
        console.logInt(tickUpper);

        // 配置 UniswapV3 适配器
        uniswapV3Adapter.setTokenConfig(
            IERC20(USDC_MAINNET),
            IERC20(WETH_MAINNET),
            5000, // 50% slippage (大幅增加滑点容忍度)
            3000, // 0.3% fee tier
            tickLower, // 使用合理的 tick 范围
            tickUpper, // 使用合理的 tick 范围
            vaultAddress
        );

        // 给金库一些 USDC 和 WETH 进行测试
        _fundVaultWithToken(USDC_MAINNET, 1000 * 1e6); // 1000 USDC
        _fundVaultWithToken(WETH_MAINNET, 1 * 1e18); // 1 WETH

        // 测试投资
        vm.prank(vaultAddress);
        IERC20(USDC_MAINNET).approve(address(uniswapV3Adapter), 1000 * 1e6);
        vm.prank(vaultAddress);
        IERC20(WETH_MAINNET).approve(address(uniswapV3Adapter), 1 * 1e18);
        vm.prank(vaultAddress);
        uniswapV3Adapter.invest(IERC20(USDC_MAINNET), 1000 * 1e6);

        // 验证投资
        uint256 totalValue = uniswapV3Adapter.getTotalValue(IERC20(USDC_MAINNET));
        assertGt(totalValue, 0, "UniswapV3 investment should have value");
        console.log("UniswapV3 total value:", totalValue);

        emit InvestmentTested("UniswapV3", 1000 * 1e6, true);
    }

    /**
     * @notice 测试多协议组合投资
     */
    function testMultiProtocolInvestment() public {
        vm.selectFork(mainnetFork);
        console.log("=== Testing Multi-Protocol Investment ===");

        _deployManager();
        _deployRealAdapters();
        _createVault();
        _configureAdapters();
        _addAdaptersToManager();

        // 设置资产分配
        uint256[] memory adapterIndices = new uint256[](3);
        adapterIndices[0] = 0; // Aave
        adapterIndices[1] = 1; // UniswapV2
        adapterIndices[2] = 2; // UniswapV3

        uint256[] memory allocationData = new uint256[](3);
        allocationData[0] = 500; // 50% to Aave
        allocationData[1] = 300; // 30% to UniswapV2
        allocationData[2] = 200; // 20% to UniswapV3

        manager.updateHoldingAllocation(IERC20(USDC_MAINNET), adapterIndices, allocationData);

        // 给用户一些 USDC 进行测试
        _fundUserWithToken(USDC_MAINNET, 10000 * 1e6); // 10000 USDC

        // 模拟用户存款
        vm.prank(user);
        IERC20(USDC_MAINNET).approve(vaultAddress, 10000 * 1e6);
        vm.prank(user);
        VaultImplementation(vaultAddress).deposit(10000 * 1e6, user);

        // 验证各协议的投资价值
        uint256 aaveValue = aaveAdapter.getTotalValue(IERC20(USDC_MAINNET));
        uint256 uniswapV2Value = uniswapV2Adapter.getTotalValue(IERC20(USDC_MAINNET));
        uint256 uniswapV3Value = uniswapV3Adapter.getTotalValue(IERC20(USDC_MAINNET));

        console.log("Aave value:", aaveValue);
        console.log("UniswapV2 value:", uniswapV2Value);
        console.log("UniswapV3 value:", uniswapV3Value);

        assertGt(aaveValue, 0, "Aave should have invested value");
        assertGt(uniswapV2Value, 0, "UniswapV2 should have invested value");
        assertGt(uniswapV3Value, 0, "UniswapV3 should have invested value");

        emit TestCompleted("Multi-Protocol Investment", true);
    }

    /**
     * @notice 测试ETH金库集成
     */
    function testETHVaultIntegration() public {
        vm.selectFork(mainnetFork);
        console.log("=== Testing ETH Vault Integration ===");

        _deployManager();
        _deployRealAdapters();
        _createVault();
        _createETHVault();
        _configureAdapters();
        _configureETHAdapters();
        _addAdaptersToManager();

        // 设置ETH金库的投资分配
        _setETHVaultAllocation();

        // 测试ETH存款和投资
        _testETHDepositAndInvestment();

        // 测试ETH提取
        _testETHRedeem();

        console.log("=== ETH Vault Integration Test Completed ===");
    }

    /**
     * @notice 测试ETH金库多协议投资
     */
    function testETHVaultMultiProtocolInvestment() public {
        vm.selectFork(mainnetFork);
        console.log("=== Testing ETH Vault Multi-Protocol Investment ===");

        _deployManager();
        _deployRealAdapters();
        _createVault();
        _createETHVault();
        _configureAdapters();
        _configureETHAdapters();
        _addAdaptersToManager();

        // 设置ETH金库的投资分配
        _setETHVaultAllocation();

        // 给用户一些ETH进行测试
        vm.deal(user, 10 ether);

        // 用户使用ETH存款到ETH金库
        vm.prank(user);
        uint256 shares = ethVault.depositETH{ value: 5 ether }(user);

        assertTrue(shares > 0, "User should receive shares");
        assertEq(ethVault.balanceOf(user), shares, "User should have correct shares");
        console.log("ETH deposit successful, received", shares, "shares");

        // 验证投资结果
        uint256 aaveValue = aaveAdapter.getTotalValue(IERC20(WETH_MAINNET));
        uint256 uniswapV2Value = uniswapV2Adapter.getTotalValue(IERC20(WETH_MAINNET));

        console.log("Aave investment value:", aaveValue);
        console.log("UniswapV2 investment value:", uniswapV2Value);

        // 验证投资分配是否正确
        assertTrue(aaveValue > 0, "Aave should have invested value");
        assertTrue(uniswapV2Value > 0, "UniswapV2 should have invested value");

        // 测试部分提取
        uint256 userSharesBefore = ethVault.balanceOf(user);
        uint256 userETHBefore = user.balance;

        vm.prank(user);
        uint256 assets = ethVault.redeemETH(userSharesBefore / 2, user, user);

        assertTrue(assets > 0, "Should receive ETH assets");
        assertGt(user.balance, userETHBefore, "User should receive ETH");
        console.log("ETH withdrawal successful, received", assets, "ETH");

        emit TestCompleted("ETH Vault Multi-Protocol Investment", true);
    }

    // ============ 内部辅助函数 ============

    function _deployManager() internal {
        // 部署实现合约
        vaultImplementation = new VaultImplementation();
        console.log("VaultImplementation deployed at:", address(vaultImplementation));

        // 部署管理器
        manager = new AIAgentVaultManager(); // 不再需要 WETH 参数
        console.log("Manager deployed at:", address(manager));

        // 部署工厂合约
        vaultFactory = new VaultFactory(address(vaultImplementation), address(manager));
        console.log("VaultFactory deployed at:", address(vaultFactory));
    }

    function _deployRealAdapters() internal {
        // 部署 Aave 适配器
        aaveAdapter = new AaveAdapter(AAVE_POOL_MAINNET);
        emit AdapterDeployed("Aave", address(aaveAdapter));

        // 部署 UniswapV2 适配器
        uniswapV2Adapter = new UniswapV2Adapter(UNISWAP_V2_ROUTER_MAINNET, UNISWAP_V2_FACTORY_MAINNET);
        emit AdapterDeployed("UniswapV2", address(uniswapV2Adapter));

        // 部署 UniswapV3 适配器
        uniswapV3Adapter = new UniswapV3Adapter(
            UNISWAP_V3_ROUTER_MAINNET, UNISWAP_V3_POSITION_MANAGER_MAINNET, UNISWAP_V3_FACTORY_MAINNET
        );
        emit AdapterDeployed("UniswapV3", address(uniswapV3Adapter));
    }

    function _createVault() internal {
        // Create vault using factory
        vaultAddress = payable(
            vaultFactory.createVault(
                IERC20(USDC_MAINNET),
                "Test USDC Vault",
                "TESTUSDC",
                1000 // 10% fee
            )
        );

        // VaultFactory already transfers ownership to manager, so no need to transfer again

        // Add vault to manager
        manager.addVault(IERC20(USDC_MAINNET), vaultAddress);

        emit VaultCreated(vaultAddress);
        assertNotEq(vaultAddress, address(0), "Vault should be created");
        console.log("Vault created at:", vaultAddress);
    }

    function _configureAdapters() internal {
        // 配置 Aave 适配器
        aaveAdapter.setTokenVault(IERC20(USDC_MAINNET), vaultAddress);

        // 配置 UniswapV2 适配器
        uniswapV2Adapter.setTokenConfig(
            IERC20(USDC_MAINNET),
            100, // 1% slippage
            IERC20(WETH_MAINNET),
            vaultAddress
        );

        // 配置 UniswapV3 适配器 - 使用更宽的 tick 范围确保流动性充足
        address poolAddress =
            IMinimalUniswapV3Factory(UNISWAP_V3_FACTORY_MAINNET).getPool(USDC_MAINNET, WETH_MAINNET, 3000);
        (, int24 currentTick,,,,,) = IMinimalUniswapV3Pool(poolAddress).slot0();

        // 首先将当前tick对齐到60的倍数
        int24 alignedCurrentTick = (currentTick / 60) * 60;

        // 使用更宽的tick范围以确保流动性充足
        int24 tickRange = 10000; // 大约 100% 的范围，确保有足够的流动性空间
        int24 tickLower = alignedCurrentTick - tickRange;
        int24 tickUpper = alignedCurrentTick + tickRange;

        // 确保 tick 对齐到 fee tier 的倍数
        // 对于 0.3% fee tier，tick 必须是 60 的倍数
        tickLower = (tickLower / 60) * 60;
        tickUpper = (tickUpper / 60) * 60;

        // 确保 tick 范围仍然有效
        if (tickLower >= tickUpper) {
            tickLower = tickUpper - 60;
        }

        // 确保tick范围不会超出UniswapV3的限制
        if (tickLower < -887200) {
            tickLower = -887200;
        }
        if (tickUpper > 887200) {
            tickUpper = 887200;
        }

        console.log("Current tick:", currentTick);
        console.log("Aligned current tick:", alignedCurrentTick);
        console.log("Calculated tick range:");
        console.logInt(tickLower);
        console.log("to");
        console.logInt(tickUpper);

        uniswapV3Adapter.setTokenConfig(
            IERC20(USDC_MAINNET),
            IERC20(WETH_MAINNET),
            5000, // 50% slippage (大幅增加滑点容忍度)
            3000, // 0.3% fee tier
            tickLower, // 使用合理的 tick 范围
            tickUpper, // 使用合理的 tick 范围
            vaultAddress
        );
    }

    function _addAdaptersToManager() internal {
        manager.addAdapter(IProtocolAdapter(address(aaveAdapter)));
        manager.addAdapter(IProtocolAdapter(address(uniswapV2Adapter)));
        manager.addAdapter(IProtocolAdapter(address(uniswapV3Adapter)));

        assertEq(manager.getAllAdapters().length, 3, "Should have 3 adapters");
        console.log("All adapters added to manager");
    }

    function _testInvestmentFlow() internal {
        console.log("Testing investment flow...");

        // 给用户一些代币进行存款
        _fundUserWithToken(USDC_MAINNET, 1000 * 1e6);

        // 模拟用户存款
        vm.prank(user);
        IERC20(USDC_MAINNET).approve(vaultAddress, 1000 * 1e6);
        VaultImplementation(vaultAddress).deposit(1000 * 1e6, user);

        console.log("Investment flow test completed");
    }

    function _testAssetManagement() internal view {
        console.log("Testing asset management...");

        // 测试资产查询 - 通过金库合约查询总资产
        uint256 totalValue = VaultImplementation(vaultAddress).totalAssets();
        assertGt(totalValue, 0, "Total value should be positive");

        console.log("Total vault value:", totalValue);
        console.log("Asset management test completed");
    }

    function _testDivestmentFlow() internal {
        console.log("Testing divestment flow...");

        // 撤回所有投资
        manager.withdrawAllInvestments(IERC20(USDC_MAINNET));

        // 验证投资已撤回
        uint256 aaveValue = aaveAdapter.getTotalValue(IERC20(USDC_MAINNET));
        uint256 uniswapV2Value = uniswapV2Adapter.getTotalValue(IERC20(USDC_MAINNET));
        uint256 uniswapV3Value = uniswapV3Adapter.getTotalValue(IERC20(USDC_MAINNET));

        assertEq(aaveValue, 0, "Aave should have 0 value after withdrawal");
        assertEq(uniswapV2Value, 0, "UniswapV2 should have 0 value after withdrawal");
        assertEq(uniswapV3Value, 0, "UniswapV3 should have 0 value after withdrawal");

        console.log("Divestment flow test completed");
    }

    function _fundUserWithToken(address token, uint256 amount) internal {
        // 在 fork 测试中，我们需要从持有大量代币的地址转账给用户
        IERC20 tokenContract = IERC20(token);

        // 找到持有大量代币的地址（这些是已知的大户地址）
        address whaleAddress;
        if (token == USDC_MAINNET) {
            // USDC 大户地址
            whaleAddress = 0xEe7aE85f2Fe2239E27D9c1E23fFFe168D63b4055;
        } else if (token == WETH_MAINNET) {
            // WETH 大户地址
            whaleAddress = 0x28C6c06298d514Db089934071355E5743bf21d60;
        } else if (token == WBTC_MAINNET) {
            // WBTC 大户地址 (Compound cWBTC)
            whaleAddress = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;
        } else if (token == USDT_MAINNET) {
            // USDT 大户地址
            whaleAddress = 0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503;
        } else {
            // 默认使用一个已知的大户地址
            whaleAddress = 0x28C6c06298d514Db089934071355E5743bf21d60;
        }

        // 检查大户地址是否有足够的代币
        uint256 whaleBalance = tokenContract.balanceOf(whaleAddress);
        console.log("Whale balance for user funding:", whaleBalance);

        if (whaleBalance >= amount) {
            // 模拟大户地址转账给用户
            vm.prank(whaleAddress);
            tokenContract.transfer(user, amount);

            uint256 newBalance = tokenContract.balanceOf(user);
            console.log("User balance after funding:", newBalance);
            console.log("Successfully funded user with", amount, "tokens");
        } else {
            console.log("Warning: Whale doesn't have enough tokens for user funding");
            console.log("Whale has:", whaleBalance, "but need:", amount);
        }
    }

    function _fundVaultWithToken(address token, uint256 amount) internal {
        // 在 fork 测试中，我们需要从持有大量代币的地址转账给金库
        IERC20 tokenContract = IERC20(token);

        // 记录当前余额
        uint256 currentBalance = tokenContract.balanceOf(vaultAddress);
        console.log("Current vault balance:", currentBalance);

        // 找到持有大量代币的地址（这些是已知的大户地址）
        address whaleAddress;
        if (token == USDC_MAINNET) {
            // USDC 大户地址 (Binance 热钱包)
            whaleAddress = 0xEe7aE85f2Fe2239E27D9c1E23fFFe168D63b4055;
        } else if (token == WETH_MAINNET) {
            // WETH 大户地址 (WETH 合约本身)
            whaleAddress = 0x28C6c06298d514Db089934071355E5743bf21d60;
        } else if (token == WBTC_MAINNET) {
            // WBTC 大户地址 (Compound cWBTC)
            whaleAddress = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;
        } else if (token == USDT_MAINNET) {
            // USDT 大户地址 (Tether Treasury)
            whaleAddress = 0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503;
        } else {
            // 默认使用一个已知的大户地址
            whaleAddress = 0x28C6c06298d514Db089934071355E5743bf21d60;
        }

        // 检查大户地址是否有足够的代币
        uint256 whaleBalance = tokenContract.balanceOf(whaleAddress);
        console.log("Whale balance:", whaleBalance);

        if (whaleBalance >= amount) {
            // 模拟大户地址转账给金库
            vm.prank(whaleAddress);
            tokenContract.transfer(vaultAddress, amount);

            uint256 newBalance = tokenContract.balanceOf(vaultAddress);
            console.log("New vault balance:", newBalance);
            console.log("Successfully funded vault with", amount, "tokens");
        } else {
            console.log("Warning: Whale doesn't have enough tokens, skipping funding");
            console.log("Whale has:", whaleBalance, "but need:", amount);
        }
    }

    // ============ ETH金库相关辅助函数 ============

    function _createETHVault() internal {
        // 创建ETH金库构造函数数据
        IVaultShares.ConstructorData memory constructorData = IVaultShares.ConstructorData({
            asset: IERC20(WETH_MAINNET),
            Fee: 100, // 1% 费用
            vaultName: "ETH Vault Guardian",
            vaultSymbol: "vgETH"
        });

        // 部署ETH金库
        ethVault = new VaultSharesETH(constructorData);

        // 转移所有权给管理器
        ethVault.transferOwnership(address(manager));

        // 添加ETH金库到管理器
        manager.addVault(IERC20(WETH_MAINNET), address(ethVault));

        emit ETHVaultCreated(address(ethVault));
        assertNotEq(address(ethVault), address(0), "ETH Vault should be created");
        console.log("ETH Vault created at:", address(ethVault));
    }

    function _configureETHAdapters() internal {
        // 配置Aave适配器以使用WETH
        aaveAdapter.setTokenVault(IERC20(WETH_MAINNET), address(ethVault));

        // 配置UniswapV2适配器以使用WETH
        uniswapV2Adapter.setTokenConfig(
            IERC20(WETH_MAINNET),
            100, // 1% slippage
            IERC20(USDC_MAINNET),
            address(ethVault)
        );

        // 配置UniswapV3适配器以使用WETH
        address poolAddress =
            IMinimalUniswapV3Factory(UNISWAP_V3_FACTORY_MAINNET).getPool(WETH_MAINNET, USDC_MAINNET, 3000);

        if (poolAddress != address(0)) {
            (, int24 currentTick,,,,,) = IMinimalUniswapV3Pool(poolAddress).slot0();

            int24 tickRange = 2000; // 大约 20% 的范围
            int24 tickLower = currentTick - tickRange;
            int24 tickUpper = currentTick + tickRange;

            // 确保 tick 对齐到 fee tier 的倍数
            tickLower = (tickLower / 60) * 60;
            tickUpper = (tickUpper / 60) * 60;

            if (tickLower >= tickUpper) {
                tickLower = tickUpper - 60;
            }

            uniswapV3Adapter.setTokenConfig(
                IERC20(WETH_MAINNET),
                IERC20(USDC_MAINNET),
                1000, // 10% slippage
                3000, // 0.3% fee tier
                tickLower,
                tickUpper,
                address(ethVault)
            );
        }
    }

    function _setETHVaultAllocation() internal {
        // 设置ETH金库的投资分配（只测试Aave和UniswapV2，因为UniswapV3需要池子存在）
        uint256[] memory adapterIndices = new uint256[](2);
        adapterIndices[0] = 0; // Aave
        adapterIndices[1] = 1; // UniswapV2

        uint256[] memory allocationData = new uint256[](2);
        allocationData[0] = 600; // 60% to Aave
        allocationData[1] = 400; // 40% to UniswapV2

        manager.updateHoldingAllocation(IERC20(WETH_MAINNET), adapterIndices, allocationData);

        console.log("ETH vault allocation set: Aave 60%, UniswapV2 40%");
    }

    function _testETHDepositAndInvestment() internal {
        console.log("Testing ETH deposit and investment...");

        // 给用户一些ETH进行测试
        vm.deal(user, 5 ether);

        // 用户使用ETH存款到ETH金库
        vm.prank(user);
        uint256 shares = ethVault.depositETH{ value: 2 ether }(user);

        assertTrue(shares > 0, "User should receive shares");
        assertEq(ethVault.balanceOf(user), shares, "User should have correct shares");
        console.log("ETH deposit successful, received", shares, "shares");

        // 验证投资结果
        uint256 aaveValue = aaveAdapter.getTotalValue(IERC20(WETH_MAINNET));
        uint256 uniswapV2Value = uniswapV2Adapter.getTotalValue(IERC20(WETH_MAINNET));

        console.log("Aave investment value:", aaveValue);
        console.log("UniswapV2 investment value:", uniswapV2Value);

        // 验证投资分配是否正确
        assertTrue(aaveValue > 0, "Aave should have invested value");
        assertTrue(uniswapV2Value > 0, "UniswapV2 should have invested value");
    }

    function _testETHRedeem() internal {
        console.log("Testing ETH redeem...");

        uint256 userSharesBefore = ethVault.balanceOf(user);
        uint256 userETHBefore = user.balance;

        // 用户提取一半的份额
        vm.prank(user);
        uint256 assets = ethVault.redeemETH(userSharesBefore / 2, user, user);

        assertTrue(assets > 0, "Should receive ETH assets");
        assertGt(user.balance, userETHBefore, "User should receive ETH");
        console.log("ETH withdrawal successful, received", assets, "ETH");
    }
}
