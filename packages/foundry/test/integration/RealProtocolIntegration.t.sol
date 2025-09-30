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
import "../mock/MockToken.sol";
import "../mock/MockAavePool.sol";
import "../mock/MockUniswapV2.sol";
import { MockUniswapV2Pair } from "../mock/MockUniswapV2.sol";
import "../mock/RealisticUniswapV3.sol";
import "../mock/MockWETH9.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title RealProtocolIntegrationTest
 * @notice 真实协议适配器集成测试
 * 测试管理者和三个真实适配器（Aave、UniswapV2、UniswapV3）的集成
 */
contract RealProtocolIntegrationTest is Test {
    // 核心合约
    AIAgentVaultManager public manager;
    VaultFactory public vaultFactory;
    MockToken public usdc;
    MockToken public weth;
    address public owner;
    address public user;

    // 真实适配器
    AaveAdapter public aaveAdapter;
    UniswapV2Adapter public uniswapV2Adapter;
    UniswapV3Adapter public uniswapV3Adapter;

    // Mock 协议合约
    MockAavePool public mockAavePool;
    MockUniswapV2Factory public mockUniswapV2Factory;
    MockUniswapV2Router public mockUniswapV2Router;
    RealisticUniswapV3Factory public realisticUniswapV3Factory;
    RealisticSwapRouter public realisticUniswapV3Router;
    RealisticNonfungiblePositionManager public realisticPositionManager;
    RealisticQuoter public realisticQuoter;

    // 金库地址
    address payable public vaultAddress;

    // ETH金库相关
    VaultSharesETH public ethVault;
    MockWETH9 public mockWETH;

    event AdapterConfigured(string adapterName, address adapterAddress);
    event VaultCreated(address vaultAddress);
    event InvestmentMade(string protocol, uint256 amount);
    event AssetAllocationUpdated(uint256[] allocations);

    function setUp() public {
        owner = address(this);
        user = address(0x123);

        // 部署代币
        usdc = new MockToken("USD Coin", "USDC");
        weth = new MockToken("Wrapped Ether", "WETH");

        // 部署MockWETH9用于ETH金库
        mockWETH = new MockWETH9();

        // 给用户一些代币用于测试
        usdc.mint(user, 10000 * 10 ** 18);
        weth.mint(user, 100 * 10 ** 18);

        // 给适配器一些 WETH 用于 UniswapV3 流动性提供
        weth.mint(address(this), 1000 * 10 ** 18);

        // 部署工厂
        VaultImplementation implementation = new VaultImplementation();

        // 部署管理器
        manager = new AIAgentVaultManager();

        vaultFactory = new VaultFactory(address(implementation), address(manager));

        // 部署 Mock 协议合约
        _deployMockProtocols();

        // 部署真实适配器
        _deployRealAdapters();

        // 先创建金库
        _createVault();

        // 创建ETH金库
        _createETHVault();

        // 然后配置适配器（使用正确的金库地址）
        _configureAdapters();
    }

    function _deployMockProtocols() internal {
        // Aave Mock
        mockAavePool = new MockAavePool();

        // 给 MockAavePool 一些 USDC 用于撤资
        usdc.mint(address(mockAavePool), 10000 * 10 ** 18);

        // UniswapV2 Mock
        mockUniswapV2Factory = new MockUniswapV2Factory();
        mockUniswapV2Router = new MockUniswapV2Router(address(mockUniswapV2Factory));

        // UniswapV3 Realistic Mock
        realisticUniswapV3Factory = new RealisticUniswapV3Factory();
        address poolAddress = realisticUniswapV3Factory.createPool(address(usdc), address(weth), 3000);

        // 给 RealisticUniswapV3Pool 一些代币用于交换
        usdc.mint(poolAddress, 10000 * 10 ** 18);
        weth.mint(poolAddress, 10000 * 10 ** 18);

        realisticUniswapV3Router = new RealisticSwapRouter(poolAddress);
        realisticPositionManager = new RealisticNonfungiblePositionManager();
        realisticQuoter = new RealisticQuoter(poolAddress);

        // 设置 position manager 的 factory 引用
        realisticPositionManager.setFactory(address(realisticUniswapV3Factory));

        // 给 RealisticNonfungiblePositionManager 一些代币用于撤资
        usdc.mint(address(realisticPositionManager), 10000 * 10 ** 18);
        weth.mint(address(realisticPositionManager), 10000 * 10 ** 18);
    }

    function _deployRealAdapters() internal {
        // 部署 Aave 适配器
        aaveAdapter = new AaveAdapter(address(mockAavePool));

        // 部署 UniswapV2 适配器
        uniswapV2Adapter = new UniswapV2Adapter(address(mockUniswapV2Router), address(mockUniswapV2Factory));

        // 部署 UniswapV3 适配器
        uniswapV3Adapter = new UniswapV3Adapter(
            address(realisticUniswapV3Router),
            address(realisticPositionManager),
            address(realisticUniswapV3Factory),
            address(realisticQuoter)
        );
    }

    function _configureAdapters() internal {
        // 配置 Aave 适配器
        // 为 USDC 创建 aToken
        mockAavePool.createAToken(address(usdc));
        mockAavePool.setReserveNormalizedIncome(address(usdc), 1e27);
        aaveAdapter.setTokenVault(IERC20(address(usdc)), vaultAddress);
        emit AdapterConfigured("Aave", address(aaveAdapter));

        // 配置 UniswapV2 适配器
        // 为 UniswapV2 创建交易对（如果不存在）
        address pairAddress;
        if (mockUniswapV2Factory.getPair(address(usdc), address(weth)) == address(0)) {
            pairAddress = mockUniswapV2Factory.createPair(address(usdc), address(weth));
        } else {
            pairAddress = mockUniswapV2Factory.getPair(address(usdc), address(weth));
        }

        // 为交易对添加初始流动性
        _addInitialLiquidityToPair(pairAddress);

        uniswapV2Adapter.setTokenConfig(
            IERC20(address(usdc)),
            100, // 1% slippage
            IERC20(address(weth)),
            vaultAddress
        );
        emit AdapterConfigured("UniswapV2", address(uniswapV2Adapter));

        // 配置 UniswapV3 适配器
        uniswapV3Adapter.setTokenConfig(
            IERC20(address(usdc)),
            IERC20(address(weth)),
            100, // 1% slippage
            3000, // 0.3% fee tier
            -600, // tick lower
            600, // tick upper
            vaultAddress
        );
        emit AdapterConfigured("UniswapV3", address(uniswapV3Adapter));

        // 配置适配器以使用WETH和ETH金库
        // 为 WETH 创建 aToken
        mockAavePool.createAToken(address(mockWETH));
        mockAavePool.setReserveNormalizedIncome(address(mockWETH), 1e27);

        // 给 MockAavePool 一些 WETH 用于撤资
        vm.deal(address(this), 1000 ether);
        mockWETH.deposit{ value: 1000 ether }();
        mockWETH.transfer(address(mockAavePool), 1000 ether);

        aaveAdapter.setTokenVault(IERC20(address(mockWETH)), address(ethVault));

        // 为UniswapV2创建WETH/USDC交易对
        address wethUsdcPair;
        if (mockUniswapV2Factory.getPair(address(mockWETH), address(usdc)) == address(0)) {
            wethUsdcPair = mockUniswapV2Factory.createPair(address(mockWETH), address(usdc));
        } else {
            wethUsdcPair = mockUniswapV2Factory.getPair(address(mockWETH), address(usdc));
        }

        // 为交易对添加初始流动性
        uint256 liquidityAmount = 1000 * 10 ** 18; // 1000 tokens
        // 给测试合约一些ETH，然后使用deposit函数将ETH转换为WETH
        vm.deal(address(this), liquidityAmount);
        mockWETH.deposit{ value: liquidityAmount }();
        usdc.mint(address(this), liquidityAmount);
        mockWETH.transfer(wethUsdcPair, liquidityAmount);
        usdc.transfer(wethUsdcPair, liquidityAmount);
        MockUniswapV2Pair(wethUsdcPair).mint(address(this));

        uniswapV2Adapter.setTokenConfig(
            IERC20(address(mockWETH)),
            100, // 1% slippage
            IERC20(address(usdc)),
            address(ethVault)
        );
    }

    function _createVault() internal {
        // Create vault using factory
        vaultAddress = payable(
            vaultFactory.createVault(
                usdc,
                string.concat("Vault Guardian ", usdc.name()),
                string.concat("vg", usdc.symbol()),
                1000 // 0.1% fee
            )
        );

        // VaultFactory already transfers ownership to manager, so no need to transfer again

        // Add vault to manager
        manager.addVault(usdc, vaultAddress);

        emit VaultCreated(vaultAddress);
        assertNotEq(vaultAddress, address(0), "Vault should be created");
    }

    function _createETHVault() internal {
        // 创建ETH金库构造函数数据
        IVaultShares.ConstructorData memory constructorData = IVaultShares.ConstructorData({
            asset: IERC20(address(mockWETH)),
            Fee: 100, // 1% 费用
            vaultName: "ETH Vault Guardian",
            vaultSymbol: "vgETH"
        });

        // 部署ETH金库
        ethVault = new VaultSharesETH(constructorData);

        // 转移所有权给管理器
        ethVault.transferOwnership(address(manager));

        // 添加ETH金库到管理器
        manager.addVault(IERC20(address(mockWETH)), address(ethVault));

        emit VaultCreated(address(ethVault));
        assertNotEq(address(ethVault), address(0), "ETH Vault should be created");
    }

    /**
     * @notice 测试完整的多协议集成流程
     */
    function testCompleteMultiProtocolIntegration() public {
        console.log("=== Starting Complete Multi-Protocol Integration Test ===");

        // 1. 金库已在setUp中创建，适配器也已配置

        // 2. 添加所有适配器到管理器
        _addAllAdapters();

        // 4. 设置初始资产分配
        _setInitialAllocation();

        // 3. 用户存款
        _userDeposit();

        // 4. 验证投资结果
        _verifyInvestments();

        // 5. 测试资产查询准确性
        _testAssetQueries();

        // 6. 测试管理者调整参数
        _testManagerParameterAdjustments();

        // 7. 测试部分资产重新分配 (UniswapV3)
        _testPartialReallocation();

        // 8. 测试UniswapV2部分资产重新分配
        _testUniswapV2PartialReallocation();

        // 9. 测试撤资流程
        _testDivestmentProcess();

        console.log("=== Multi-Protocol Integration Test Completed ===");
    }

    function _addAllAdapters() internal {
        vm.startPrank(owner);
        manager.addAdapter(IProtocolAdapter(address(aaveAdapter)));
        manager.addAdapter(IProtocolAdapter(address(uniswapV2Adapter)));
        manager.addAdapter(IProtocolAdapter(address(uniswapV3Adapter)));
        vm.stopPrank();

        // 验证适配器已添加
        assertTrue(manager.isAdapterApproved(IProtocolAdapter(address(aaveAdapter))), "Aave adapter should be approved");
        assertTrue(
            manager.isAdapterApproved(IProtocolAdapter(address(uniswapV2Adapter))),
            "UniswapV2 adapter should be approved"
        );
        assertTrue(
            manager.isAdapterApproved(IProtocolAdapter(address(uniswapV3Adapter))),
            "UniswapV3 adapter should be approved"
        );
        assertEq(manager.getAllAdapters().length, 3, "Should have 3 adapters");

        console.log(" All adapters added to manager");
    }

    function _setInitialAllocation() internal {
        uint256[] memory adapterIndices = new uint256[](3);
        adapterIndices[0] = 0; // Aave
        adapterIndices[1] = 1; // UniswapV2
        adapterIndices[2] = 2; // UniswapV3

        uint256[] memory allocationData = new uint256[](3);
        allocationData[0] = 500; // 50% to Aave
        allocationData[1] = 300; // 30% to UniswapV2
        allocationData[2] = 200; // 20% to UniswapV3

        manager.updateHoldingAllocation(usdc, adapterIndices, allocationData);

        emit AssetAllocationUpdated(allocationData);
        console.log(" Initial asset allocation set: Aave 50%, UniswapV2 30%, UniswapV3 20%");
    }

    function _userDeposit() internal {
        uint256 depositAmount = 1000 * 10 ** 18; // 1000 USDC

        vm.startPrank(user);
        usdc.approve(vaultAddress, depositAmount);
        uint256 shares = VaultImplementation(vaultAddress).deposit(depositAmount, user);
        vm.stopPrank();

        assertGt(shares, 0, "User should receive shares");
        console.log(" User deposit completed, received", shares, "shares");
    }

    function _verifyInvestments() internal {
        // 验证 Aave 投资
        uint256 aaveValue = aaveAdapter.getTotalValue(IERC20(address(usdc)));
        assertGt(aaveValue, 0, "Aave should have invested value");
        console.log(" Aave investment value:", aaveValue);

        // 验证 UniswapV2 投资
        uint256 uniswapV2Value = uniswapV2Adapter.getTotalValue(IERC20(address(usdc)));
        assertGt(uniswapV2Value, 0, "UniswapV2 should have invested value");
        console.log(" UniswapV2 investment value:", uniswapV2Value);

        // 验证 UniswapV3 投资
        uint256 uniswapV3Value = uniswapV3Adapter.getTotalValue(IERC20(address(usdc)));
        assertGt(uniswapV3Value, 0, "UniswapV3 should have invested value");
        console.log(" UniswapV3 investment value:", uniswapV3Value);

        emit InvestmentMade("Aave", aaveValue);
        emit InvestmentMade("UniswapV2", uniswapV2Value);
        emit InvestmentMade("UniswapV3", uniswapV3Value);
    }

    function _testAssetQueries() internal view {
        console.log("=== Testing Asset Query Accuracy ===");

        // 测试各适配器的资产查询
        uint256 aaveValue = aaveAdapter.getTotalValue(IERC20(address(usdc)));
        uint256 uniswapV2Value = uniswapV2Adapter.getTotalValue(IERC20(address(usdc)));
        uint256 uniswapV3Value = uniswapV3Adapter.getTotalValue(IERC20(address(usdc)));

        // 验证查询结果的一致性
        assertTrue(aaveValue > 0, "Aave value should be positive");
        assertTrue(uniswapV2Value > 0, "UniswapV2 value should be positive");
        assertTrue(uniswapV3Value > 0, "UniswapV3 value should be positive");

        // 测试适配器名称查询
        assertEq(aaveAdapter.getName(), "Aave", "Aave adapter name should match");
        assertEq(uniswapV2Adapter.getName(), "UniswapV2", "UniswapV2 adapter name should match");
        assertEq(uniswapV3Adapter.getName(), "UniswapV3", "UniswapV3 adapter name should match");

        console.log(" Asset query accuracy verification passed");
    }

    function _testManagerParameterAdjustments() internal {
        console.log("=== Testing Manager Parameter Adjustments ===");

        // 1. 测试通过管理器执行适配器调用 - 获取名字
        bytes memory data = abi.encodeWithSelector(aaveAdapter.getName.selector);
        manager.execute(0, 0, data);
        // Should not revert - the call succeeded

        // 2. 先设置适配器的owner为manager，然后测试通过管理器更新UniswapV2的滑点容忍度
        console.log("Testing UniswapV2 slippage tolerance update...");

        // 设置UniswapV2适配器的owner为manager
        vm.prank(owner);
        uniswapV2Adapter.transferOwnership(address(manager));

        uint256 newSlippageV2 = 200; // 2%
        bytes memory updateSlippageV2Data =
            abi.encodeWithSelector(uniswapV2Adapter.UpdateTokenSlippageTolerance.selector, usdc, newSlippageV2);

        manager.execute(1, 0, updateSlippageV2Data);

        // 验证滑点容忍度是否更新
        UniswapV2Adapter.TokenConfig memory configV2 = uniswapV2Adapter.getTokenConfig(usdc);
        assertEq(configV2.slippageTolerance, newSlippageV2, "UniswapV2 slippage tolerance should be updated");

        // 3. 设置UniswapV3适配器的owner为manager，然后测试通过管理器更新UniswapV3的滑点容忍度
        console.log("Testing UniswapV3 slippage tolerance update...");

        // 设置UniswapV3适配器的owner为manager
        vm.prank(owner);
        uniswapV3Adapter.transferOwnership(address(manager));

        uint256 newSlippageV3 = 150; // 1.5%
        bytes memory updateSlippageV3Data =
            abi.encodeWithSelector(uniswapV3Adapter.UpdateTokenSlippageTolerance.selector, usdc, newSlippageV3);

        manager.execute(2, 0, updateSlippageV3Data);

        // 验证滑点容忍度是否更新
        UniswapV3Adapter.TokenConfig memory configV3 = uniswapV3Adapter.getTokenConfig(usdc);
        assertEq(configV3.slippageTolerance, newSlippageV3, "UniswapV3 slippage tolerance should be updated");

        // 4. 测试批量调用 - 获取所有适配器的名字
        uint256[] memory adapterIndices = new uint256[](3);
        adapterIndices[0] = 0; // Aave
        adapterIndices[1] = 1; // UniswapV2
        adapterIndices[2] = 2; // UniswapV3

        uint256[] memory values = new uint256[](3);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;

        bytes[] memory callData = new bytes[](3);
        callData[0] = abi.encodeWithSelector(aaveAdapter.getName.selector);
        callData[1] = abi.encodeWithSelector(uniswapV2Adapter.getName.selector);
        callData[2] = abi.encodeWithSelector(uniswapV3Adapter.getName.selector);

        manager.executeBatch(adapterIndices, values, callData);

        // Should not revert - the calls succeeded

        // 5. 测试通过管理器更新UniswapV3的TokenConfig（最重要的策略更新）
        console.log("Testing UniswapV3 TokenConfig update...");

        // 记录更新前的配置
        UniswapV3Adapter.TokenConfig memory configBefore = uniswapV3Adapter.getTokenConfig(usdc);
        console.log("UniswapV3 config before update - tokenId:", configBefore.tokenId);

        // 通过manager调用UpdateTokenConfig
        bytes memory updateConfigData = abi.encodeWithSelector(
            uniswapV3Adapter.UpdateTokenConfig.selector,
            usdc,
            weth,
            3000, // 使用已存在的feeTier: 0.3%
            -1000, // 新的tickLower
            1000 // 新的tickUpper
        );

        manager.execute(2, 0, updateConfigData);

        // 验证配置是否更新
        UniswapV3Adapter.TokenConfig memory configAfter = uniswapV3Adapter.getTokenConfig(usdc);
        assertEq(address(configAfter.counterPartyToken), address(weth), "Counter party token should be updated");
        // 注意：滑点容忍度保持之前设置的值150，因为UpdateTokenConfig不会重置它
        assertEq(configAfter.slippageTolerance, 150, "Slippage tolerance should remain unchanged");
        console.log("UniswapV3 config after update - tokenId:", configAfter.tokenId);

        // 6. 测试通过管理器更新UniswapV2的TokenConfig
        console.log("Testing UniswapV2 TokenConfig update...");

        // 记录更新前的配置
        UniswapV2Adapter.TokenConfig memory configV2Before = uniswapV2Adapter.getTokenConfig(usdc);
        console.log("UniswapV2 config before update - counterPartyToken:", address(configV2Before.counterPartyToken));

        // 通过manager调用updateTokenConfigAndReinvest
        bytes memory updateConfigV2Data =
            abi.encodeWithSelector(uniswapV2Adapter.updateTokenConfigAndReinvest.selector, usdc, weth);

        manager.execute(1, 0, updateConfigV2Data);

        // 验证配置是否更新
        UniswapV2Adapter.TokenConfig memory configV2After = uniswapV2Adapter.getTokenConfig(usdc);
        assertEq(
            address(configV2After.counterPartyToken), address(weth), "UniswapV2 counter party token should be updated"
        );
        console.log("UniswapV2 config after update - counterPartyToken:", address(configV2After.counterPartyToken));

        // 7. 测试批量更新滑点容忍度
        console.log("Testing batch slippage tolerance updates...");
        uint256[] memory batchAdapterIndices = new uint256[](2);
        batchAdapterIndices[0] = 1; // UniswapV2
        batchAdapterIndices[1] = 2; // UniswapV3

        uint256[] memory batchValues = new uint256[](2);
        batchValues[0] = 0;
        batchValues[1] = 0;

        bytes[] memory batchCallData = new bytes[](2);
        batchCallData[0] = abi.encodeWithSelector(
            uniswapV2Adapter.UpdateTokenSlippageTolerance.selector,
            usdc,
            300 // 3%
        );
        batchCallData[1] = abi.encodeWithSelector(
            uniswapV3Adapter.UpdateTokenSlippageTolerance.selector,
            usdc,
            250 // 2.5%
        );

        manager.executeBatch(batchAdapterIndices, batchValues, batchCallData);

        // 验证批量更新后的滑点容忍度
        UniswapV2Adapter.TokenConfig memory finalConfigV2 = uniswapV2Adapter.getTokenConfig(usdc);
        UniswapV3Adapter.TokenConfig memory finalConfigV3 = uniswapV3Adapter.getTokenConfig(usdc);

        assertEq(finalConfigV2.slippageTolerance, 300, "UniswapV2 slippage tolerance should be updated via batch");
        assertEq(finalConfigV3.slippageTolerance, 250, "UniswapV3 slippage tolerance should be updated via batch");

        console.log(" Manager parameter adjustment functionality verified");
    }

    function _testPartialReallocation() internal {
        console.log("=== Testing Partial Asset Reallocation ===");

        // 记录重新分配前的价值
        uint256 aaveValueBefore = aaveAdapter.getTotalValue(IERC20(address(usdc)));
        uint256 uniswapV2ValueBefore = uniswapV2Adapter.getTotalValue(IERC20(address(usdc)));
        uint256 uniswapV3ValueBefore = uniswapV3Adapter.getTotalValue(IERC20(address(usdc)));

        // 从 Aave 撤资 100 USDC，投资到 UniswapV3
        uint256[] memory divestAdapterIndices = new uint256[](1);
        divestAdapterIndices[0] = 0; // Aave

        uint256[] memory divestAmounts = new uint256[](1);
        divestAmounts[0] = 100 * 10 ** 18; // 100 USDC

        uint256[] memory investAdapterIndices = new uint256[](1);
        investAdapterIndices[0] = 2; // UniswapV3

        uint256[] memory investAmounts = new uint256[](1);
        investAmounts[0] = 100 * 10 ** 18; // 100 USDC

        uint256[] memory investAllocations = new uint256[](1);
        investAllocations[0] = 300; // UniswapV3 的新分配比例

        // 在投资前给 UniswapV3 适配器一些 WETH
        weth.transfer(address(uniswapV3Adapter), 10 * 10 ** 18);

        console.log("UniswapV3 value before investment:", uniswapV3ValueBefore);
        console.log("Aave value before divestment:", aaveValueBefore);
        console.log("UniswapV2 value before divestment:", uniswapV2ValueBefore);
        console.log("USDC balance of vault before:", usdc.balanceOf(vaultAddress));
        console.log("USDC balance of Aave adapter before:", usdc.balanceOf(address(aaveAdapter)));
        console.log("USDC balance of UniswapV3 adapter before:", usdc.balanceOf(address(uniswapV3Adapter)));
        console.log("WETH balance of UniswapV3 adapter before:", weth.balanceOf(address(uniswapV3Adapter)));

        // 检查 Aave 适配器的 aToken 余额
        try aaveAdapter.getTotalValue(IERC20(address(usdc))) returns (uint256 value) {
            console.log("Aave adapter total value:", value);
        } catch {
            console.log("Failed to get Aave adapter total value");
        }

        manager.partialUpdateHoldingAllocation(
            usdc, divestAdapterIndices, divestAmounts, investAdapterIndices, investAmounts, investAllocations
        );

        console.log("USDC balance of vault after divestment:", usdc.balanceOf(vaultAddress));
        console.log("USDC balance of Aave adapter after divestment:", usdc.balanceOf(address(aaveAdapter)));

        console.log("USDC balance of UniswapV3 adapter after:", usdc.balanceOf(address(uniswapV3Adapter)));
        console.log("WETH balance of UniswapV3 adapter after:", weth.balanceOf(address(uniswapV3Adapter)));

        // 检查 UniswapV3 适配器的 tokenId
        try uniswapV3Adapter.getTokenConfig(usdc) returns (UniswapV3Adapter.TokenConfig memory config) {
            console.log("UniswapV3 tokenId:", config.tokenId);
        } catch {
            console.log("Failed to get UniswapV3 token config");
        }

        // 验证重新分配后的价值变化
        uint256 aaveValueAfter = aaveAdapter.getTotalValue(IERC20(address(usdc)));
        uint256 uniswapV3ValueAfter = uniswapV3Adapter.getTotalValue(IERC20(address(usdc)));

        assertLt(aaveValueAfter, aaveValueBefore, "Aave value should decrease after divestment");
        assertGt(uniswapV3ValueAfter, uniswapV3ValueBefore, "UniswapV3 value should increase after investment");

        console.log(" Partial asset reallocation verification passed");
    }

    function _testUniswapV2PartialReallocation() internal {
        console.log("=== Testing UniswapV2 Partial Asset Reallocation ===");

        // 记录重新分配前的价值
        uint256 aaveValueBefore = aaveAdapter.getTotalValue(IERC20(address(usdc)));
        uint256 uniswapV2ValueBefore = uniswapV2Adapter.getTotalValue(IERC20(address(usdc)));
        uint256 uniswapV3ValueBefore = uniswapV3Adapter.getTotalValue(IERC20(address(usdc)));

        // 从 Aave 撤资 50 USDC，投资到 UniswapV2
        uint256[] memory divestAdapterIndices = new uint256[](1);
        divestAdapterIndices[0] = 0; // Aave

        uint256[] memory divestAmounts = new uint256[](1);
        divestAmounts[0] = 50 * 10 ** 18; // 50 USDC

        uint256[] memory investAdapterIndices = new uint256[](1);
        investAdapterIndices[0] = 1; // UniswapV2

        uint256[] memory investAmounts = new uint256[](1);
        investAmounts[0] = 50 * 10 ** 18; // 50 USDC

        uint256[] memory investAllocations = new uint256[](1);
        investAllocations[0] = 350; // UniswapV2 的新分配比例

        console.log("Aave value before divestment:", aaveValueBefore);
        console.log("UniswapV2 value before investment:", uniswapV2ValueBefore);
        console.log("UniswapV3 value before investment:", uniswapV3ValueBefore);

        manager.partialUpdateHoldingAllocation(
            usdc, divestAdapterIndices, divestAmounts, investAdapterIndices, investAmounts, investAllocations
        );

        // 验证重新分配后的价值变化
        uint256 aaveValueAfter = aaveAdapter.getTotalValue(IERC20(address(usdc)));
        uint256 uniswapV2ValueAfter = uniswapV2Adapter.getTotalValue(IERC20(address(usdc)));

        assertLt(aaveValueAfter, aaveValueBefore, "Aave value should decrease after divestment");
        assertGt(uniswapV2ValueAfter, uniswapV2ValueBefore, "UniswapV2 value should increase after investment");

        console.log(" UniswapV2 partial asset reallocation verification passed");
    }

    function _testDivestmentProcess() internal {
        console.log("=== Testing Divestment Process ===");

        // 记录撤资前的价值
        uint256 aaveValueBefore = aaveAdapter.getTotalValue(IERC20(address(usdc)));
        uint256 uniswapV2ValueBefore = uniswapV2Adapter.getTotalValue(IERC20(address(usdc)));
        uint256 uniswapV3ValueBefore = uniswapV3Adapter.getTotalValue(IERC20(address(usdc)));
        console.log("UniswapV2 value before withdrawal:", uniswapV2ValueBefore);
        console.log("UniswapV3 value before withdrawal:", uniswapV3ValueBefore);
        console.log("Aave value before withdrawal:", aaveValueBefore);

        // 撤回所有投资
        manager.withdrawAllInvestments(usdc);

        // 验证所有投资已撤回
        uint256 aaveValueAfter = aaveAdapter.getTotalValue(IERC20(address(usdc)));
        uint256 uniswapV2ValueAfter = uniswapV2Adapter.getTotalValue(IERC20(address(usdc)));
        uint256 uniswapV3ValueAfter = uniswapV3Adapter.getTotalValue(IERC20(address(usdc)));

        assertEq(aaveValueAfter, 0, "Aave should have 0 value after withdrawal");
        assertEq(uniswapV2ValueAfter, 0, "UniswapV2 should have 0 value after withdrawal");
        assertEq(uniswapV3ValueAfter, 0, "UniswapV3 should have 0 value after withdrawal");

        console.log(" Divestment process verification passed");
    }

    /**
     * @notice 测试适配器兼容性
     */
    function testAdapterCompatibility() public {
        console.log("=== Testing Adapter Compatibility ===");

        // 测试所有适配器都实现了标准接口
        assertTrue(_implementsInterface(address(aaveAdapter)), "Aave adapter should implement IProtocolAdapter");
        assertTrue(
            _implementsInterface(address(uniswapV2Adapter)), "UniswapV2 adapter should implement IProtocolAdapter"
        );
        assertTrue(
            _implementsInterface(address(uniswapV3Adapter)), "UniswapV3 adapter should implement IProtocolAdapter"
        );

        // 测试适配器方法调用
        _testAdapterMethodCalls();

        console.log(" Adapter compatibility verification passed");
    }

    function _implementsInterface(address adapter) internal view returns (bool) {
        try IProtocolAdapter(adapter).getName() returns (string memory) {
            return true;
        } catch {
            return false;
        }
    }

    function _testAdapterMethodCalls() internal {
        // 测试 invest 方法（需要先设置金库地址）
        aaveAdapter.setTokenVault(IERC20(address(usdc)), vaultAddress);

        // 给金库一些代币进行测试
        usdc.mint(vaultAddress, 100 * 10 ** 18);

        // 让金库投资到 Aave
        vm.prank(vaultAddress);
        usdc.approve(address(aaveAdapter), 100 * 10 ** 18);
        vm.prank(vaultAddress);
        aaveAdapter.invest(IERC20(address(usdc)), 100 * 10 ** 18);

        // 测试 getTotalValue
        uint256 value = aaveAdapter.getTotalValue(IERC20(address(usdc)));
        assertGt(value, 0, "Adapter should have some value");

        // 测试 getName
        string memory name = aaveAdapter.getName();
        assertEq(name, "Aave", "Adapter name should be correct");
    }

    /**
     * @notice 测试错误处理
     */
    function testErrorHandling() public {
        console.log("=== Testing Error Handling ===");

        // 测试非金库地址调用 invest
        vm.prank(user);
        vm.expectRevert();
        aaveAdapter.invest(IERC20(address(usdc)), 100 * 10 ** 18);

        // 测试未配置的代币
        MockToken newToken = new MockToken("New Token", "NEW");
        vm.expectRevert();
        aaveAdapter.getTotalValue(IERC20(address(newToken)));

        console.log(" Error handling verification passed");
    }

    /**
     * @notice 测试金库状态管理
     */
    function testVaultStateManagement() public {
        console.log("=== Test Vault state manager ===");

        // 验证金库初始状态
        assertTrue(VaultImplementation(vaultAddress).getIsActive(), "Vault should be active initially");

        // 设置金库为非活跃状态
        manager.setVaultNotActive(usdc);

        // 验证金库状态已改变
        assertFalse(VaultImplementation(vaultAddress).getIsActive(), "Vault should be inactive after setting");

        console.log(" Test Vault state manager pass");
    }

    /**
     * @notice 测试ETH金库集成
     */
    function testETHVaultIntegration() public {
        console.log("=== Testing ETH Vault Integration ===");

        // 给用户一些ETH用于测试
        vm.deal(user, 10 ether);

        // 1. 首先配置适配器（在用户存款之前）
        console.log("Setting up adapters for ETH vault...");

        // 添加适配器到管理器（如果还没有添加）
        vm.startPrank(owner);
        try manager.addAdapter(IProtocolAdapter(address(aaveAdapter))) { } catch { }
        try manager.addAdapter(IProtocolAdapter(address(uniswapV2Adapter))) { } catch { }
        // 暂时跳过UniswapV3，因为需要池子存在
        // try manager.addAdapter(IProtocolAdapter(address(uniswapV3Adapter))) {} catch {}
        vm.stopPrank();

        // 配置适配器以使用WETH
        // 为 WETH 创建 aToken
        mockAavePool.createAToken(address(mockWETH));
        mockAavePool.setReserveNormalizedIncome(address(mockWETH), 1e27);

        // 给 MockAavePool 一些 WETH 用于撤资
        vm.deal(address(this), 1000 ether);
        mockWETH.deposit{ value: 1000 ether }();
        mockWETH.transfer(address(mockAavePool), 1000 ether);

        aaveAdapter.setTokenVault(IERC20(address(mockWETH)), address(ethVault));

        // 为UniswapV2创建WETH/USDC交易对
        address wethUsdcPair;
        if (mockUniswapV2Factory.getPair(address(mockWETH), address(usdc)) == address(0)) {
            wethUsdcPair = mockUniswapV2Factory.createPair(address(mockWETH), address(usdc));
        } else {
            wethUsdcPair = mockUniswapV2Factory.getPair(address(mockWETH), address(usdc));
        }

        // 为交易对添加初始流动性
        uint256 liquidityAmount = 1000 * 10 ** 18; // 1000 tokens
        // 给测试合约一些ETH，然后使用deposit函数将ETH转换为WETH
        vm.deal(address(this), liquidityAmount);
        mockWETH.deposit{ value: liquidityAmount }();
        usdc.mint(address(this), liquidityAmount);
        mockWETH.transfer(wethUsdcPair, liquidityAmount);
        usdc.transfer(wethUsdcPair, liquidityAmount);
        MockUniswapV2Pair(wethUsdcPair).mint(address(this));

        uniswapV2Adapter.setTokenConfig(
            IERC20(address(mockWETH)),
            100, // 1% slippage
            IERC20(address(usdc)),
            address(ethVault)
        );
        // 暂时跳过UniswapV3配置
        // uniswapV3Adapter.setTokenConfig(...)

        // 通过管理器设置ETH金库的投资分配（只测试Aave和UniswapV2）
        uint256[] memory adapterIndices = new uint256[](2);
        adapterIndices[0] = 0; // Aave
        adapterIndices[1] = 1; // UniswapV2

        uint256[] memory allocationData = new uint256[](2);
        allocationData[0] = 600; // 60% to Aave
        allocationData[1] = 400; // 40% to UniswapV2

        manager.updateHoldingAllocation(IERC20(address(mockWETH)), adapterIndices, allocationData);

        // 2. 现在用户存款，资金会自动导向不同的协议
        console.log("Testing ETH vault basic functionality...");

        // 用户使用ETH存款到ETH金库
        vm.prank(user);
        uint256 shares = ethVault.depositETH{ value: 1 ether }(user);

        assertTrue(shares > 0, "User should receive shares");
        assertEq(ethVault.balanceOf(user), shares, "User should have correct shares");
        console.log("ETH deposit successful, received", shares, "shares");

        // 验证投资结果
        uint256 aaveValue = aaveAdapter.getTotalValue(IERC20(address(mockWETH)));
        uint256 uniswapV2Value = uniswapV2Adapter.getTotalValue(IERC20(address(mockWETH)));

        console.log("Aave investment value:", aaveValue);
        console.log("UniswapV2 investment value:", uniswapV2Value);

        // 验证投资分配是否正确
        assertTrue(aaveValue > 0, "Aave should have invested value");
        assertTrue(uniswapV2Value > 0, "UniswapV2 should have invested value");

        // 4. 测试ETH提取
        console.log("Testing ETH withdrawal...");

        uint256 userSharesBefore = ethVault.balanceOf(user);
        uint256 userETHBefore = user.balance;

        vm.prank(user);
        uint256 assets = ethVault.redeemETH(userSharesBefore / 2, user, user);

        assertTrue(assets > 0, "Should receive ETH assets");
        assertGt(user.balance, userETHBefore, "User should receive ETH");
        console.log("ETH withdrawal successful, received", assets, "ETH");

        console.log(" ETH Vault Integration Test Completed");
    }

    /**
     * @notice 为 UniswapV2 交易对添加初始流动性
     * @param pairAddress 交易对地址
     */
    function _addInitialLiquidityToPair(address pairAddress) internal {
        // 给测试合约一些代币用于添加流动性
        uint256 liquidityAmount = 10000 * 10 ** 18; // 10000 tokens
        usdc.mint(address(this), liquidityAmount);
        weth.mint(address(this), liquidityAmount);

        // 将代币转移到交易对
        usdc.transfer(pairAddress, liquidityAmount);
        weth.transfer(pairAddress, liquidityAmount);

        // 添加初始流动性
        MockUniswapV2Pair(pairAddress).mint(address(this));
    }
}
