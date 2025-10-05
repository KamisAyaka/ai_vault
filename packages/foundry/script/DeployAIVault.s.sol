//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./DeployHelpers.s.sol";
import "../contracts/protocol/AIAgentVaultManager.sol";
import "../contracts/protocol/VaultFactory.sol";
import "../contracts/protocol/VaultImplementation.sol";
import "../contracts/protocol/VaultSharesETH.sol";
import "../contracts/protocol/investableUniverseAdapters/AaveAdapter.sol";
import "../contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol";
import "../contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol";
import "../test/mock/MockToken.sol";
import "../test/mock/MockWETH9.sol";
import "../test/mock/MockAavePool.sol";
import "../test/mock/MockUniswapV2.sol";
import "../test/mock/RealisticUniswapV3.sol";

/**
 * @title DeployAIVault
 * @notice Deploy all contracts of AI Vault system to local test chain
 * @dev Includes manager, vaults, adapters and Mock protocol contracts
 *
 * Usage:
 * yarn deploy --file DeployAIVault.s.sol  # Deploy to local anvil chain
 * yarn deploy --file DeployAIVault.s.sol --network sepolia  # Deploy to testnet
 */
contract DeployAIVault is ScaffoldETHDeploy {
    // 核心合约
    AIAgentVaultManager public manager;
    VaultFactory public vaultFactory;
    VaultImplementation public vaultImplementation;

    // 代币合约
    MockToken public usdc;
    MockToken public usdt;
    MockWETH9 public weth;

    // 金库合约
    address public usdcVault;
    address public usdtVault;
    address public ethVault;

    // 适配器合约
    AaveAdapter public aaveAdapter;
    UniswapV2Adapter public uniswapV2Adapter;
    UniswapV3Adapter public uniswapV3Adapter;

    // Mock协议合约
    MockAavePool public mockAavePool;
    MockUniswapV2Factory public mockUniswapV2Factory;
    MockUniswapV2Router public mockUniswapV2Router;
    RealisticUniswapV3Factory public realisticUniswapV3Factory;
    RealisticSwapRouter public realisticUniswapV3Router;
    RealisticNonfungiblePositionManager public realisticPositionManager;
    RealisticQuoter public realisticQuoter;

    /**
     * @notice Main deployment function
     * @dev Deploy all contracts in order and configure them
     */
    function run() external ScaffoldEthDeployerRunner {
        console.log("=== Starting AI Vault System Deployment ===");
        console.log("Deployer address:", deployer);
        console.log("Chain ID:", block.chainid);

        // 1. Deploy token contracts
        _deployTokens();

        // 2. Deploy manager first (needed for factory)
        _deployManager();

        // 3. Deploy factory and implementation
        _deployFactory();

        // 4. Deploy Mock protocol contracts
        _deployMockProtocols();

        // 5. Deploy adapters
        _deployAdapters();

        // 6. Create vaults
        _createVaults();

        // 7. Configure system
        _configureSystem();

        // 8. Output deployment info
        _logDeploymentInfo();

        // 9. Transfer ownership to admin
        _transferOwnershipToAdmin();

        console.log("=== AI Vault System Deployment Completed ===");
    }

    /**
     * @notice Deploy token contracts
     */
    function _deployTokens() internal {
        console.log("\n--- Deploying Token Contracts ---");

        // Deploy stablecoins
        usdc = new MockToken("USD Coin", "USDC");
        console.log("USDC deployed at:", address(usdc));

        usdt = new MockToken("Tether USD", "USDT");
        console.log("USDT deployed at:", address(usdt));

        // Deploy WETH
        weth = new MockWETH9();
        console.log("WETH deployed at:", address(weth));

        // Mint tokens to deployer for testing
        usdc.mint(deployer, 1000000 * 10 ** 18);
        usdt.mint(deployer, 1000000 * 10 ** 18);
        // WETH doesn't need minting - it's created through deposit()

        console.log("Deployer USDC balance:", usdc.balanceOf(deployer) / 10 ** 18);
        console.log("Deployer USDT balance:", usdt.balanceOf(deployer) / 10 ** 18);
        console.log("Deployer WETH balance:", weth.balanceOf(deployer) / 10 ** 18);
    }

    /**
     * @notice Deploy manager contract
     */
    function _deployManager() internal {
        console.log("\n--- Deploying Manager Contract ---");

        manager = new AIAgentVaultManager(); // 不再需要 WETH 参数
        console.log("Manager deployed at:", address(manager));

        // Note: Ownership transfer should be done after deployment completes
        // Use TransferOwnership.s.sol script to transfer ownership to admin
        console.log("Manager owner:", manager.owner());

        // Record deployment
        deployments.push(Deployment("AIAgentVaultManager", address(manager)));
    }

    /**
     * @notice Deploy factory and implementation contracts
     */
    function _deployFactory() internal {
        console.log("\n--- Deploying Factory Contracts ---");

        // Deploy implementation contract
        vaultImplementation = new VaultImplementation();
        console.log("VaultImplementation deployed at:", address(vaultImplementation));
        deployments.push(Deployment("VaultImplementation", address(vaultImplementation)));

        // Deploy factory contract
        vaultFactory = new VaultFactory(address(vaultImplementation), address(manager));
        console.log("VaultFactory deployed at:", address(vaultFactory));
        deployments.push(Deployment("VaultFactory", address(vaultFactory)));
    }

    /**
     * @notice Deploy Mock protocol contracts
     */
    function _deployMockProtocols() internal {
        console.log("\n--- Deploying Mock Protocol Contracts ---");

        // Aave Mock
        mockAavePool = new MockAavePool();
        console.log("MockAavePool deployed at:", address(mockAavePool));

        // Mint tokens to MockAavePool for divestment - need all token types
        usdc.mint(address(mockAavePool), 10000000 * 10 ** 18);
        usdt.mint(address(mockAavePool), 10000000 * 10 ** 18);
        weth.mint(address(mockAavePool), 10000000 * 10 ** 18);
        console.log("MockAavePool funded with USDC, USDT, and WETH");

        // UniswapV2 Mock
        mockUniswapV2Factory = new MockUniswapV2Factory();
        mockUniswapV2Router = new MockUniswapV2Router(address(mockUniswapV2Factory));
        console.log("MockUniswapV2Factory deployed at:", address(mockUniswapV2Factory));
        console.log("MockUniswapV2Router deployed at:", address(mockUniswapV2Router));

        // UniswapV3 Mock
        realisticUniswapV3Factory = new RealisticUniswapV3Factory();
        address usdcPoolAddress = realisticUniswapV3Factory.createPool(address(usdc), address(weth), 3000);
        address usdtPoolAddress = realisticUniswapV3Factory.createPool(address(usdt), address(weth), 3000);
        console.log("RealisticUniswapV3Factory deployed at:", address(realisticUniswapV3Factory));
        console.log("USDC/WETH pool address:", usdcPoolAddress);
        console.log("USDT/WETH pool address:", usdtPoolAddress);

        // Mint tokens to pools for swapping
        usdc.mint(usdcPoolAddress, 1000000 * 10 ** 18);
        weth.mint(usdcPoolAddress, 1000000 * 10 ** 18);
        usdt.mint(usdtPoolAddress, 1000000 * 10 ** 18);
        weth.mint(usdtPoolAddress, 1000000 * 10 ** 18);

        realisticUniswapV3Router = new RealisticSwapRouter(usdcPoolAddress);
        realisticPositionManager = new RealisticNonfungiblePositionManager();
        // 传入工厂地址，让 Quoter 能够处理所有池子
        realisticQuoter = new RealisticQuoter(usdcPoolAddress, address(realisticUniswapV3Factory));

        // Set factory reference for position manager
        realisticPositionManager.setFactory(address(realisticUniswapV3Factory));

        // Mint tokens to RealisticNonfungiblePositionManager for divestment
        usdc.mint(address(realisticPositionManager), 10000000 * 10 ** 18);
        usdt.mint(address(realisticPositionManager), 10000000 * 10 ** 18);
        weth.mint(address(realisticPositionManager), 10000000 * 10 ** 18);
        console.log("RealisticPositionManager funded with USDC, USDT, and WETH");

        // Add initial liquidity to USDC/WETH pool
        _addInitialLiquidityToUniswapV3Pool(usdcPoolAddress, usdc, weth);

        // Add initial liquidity to USDT/WETH pool
        _addInitialLiquidityToUniswapV3Pool(usdtPoolAddress, usdt, weth);

        console.log("RealisticSwapRouter deployed at:", address(realisticUniswapV3Router));
        console.log("RealisticPositionManager deployed at:", address(realisticPositionManager));
        console.log("RealisticQuoter deployed at:", address(realisticQuoter));
    }

    /**
     * @notice Deploy adapter contracts
     */
    function _deployAdapters() internal {
        console.log("\n--- Deploying Adapter Contracts ---");

        // Deploy Aave adapter
        aaveAdapter = new AaveAdapter(address(mockAavePool));
        console.log("AaveAdapter deployed at:", address(aaveAdapter));
        deployments.push(Deployment("AaveAdapter", address(aaveAdapter)));

        // Deploy UniswapV2 adapter
        uniswapV2Adapter = new UniswapV2Adapter(address(mockUniswapV2Router), address(mockUniswapV2Factory));
        console.log("UniswapV2Adapter deployed at:", address(uniswapV2Adapter));
        deployments.push(Deployment("UniswapV2Adapter", address(uniswapV2Adapter)));

        // Deploy UniswapV3 adapter
        uniswapV3Adapter = new UniswapV3Adapter(
            address(realisticUniswapV3Router),
            address(realisticPositionManager),
            address(realisticUniswapV3Factory),
            address(realisticQuoter)
        );
        console.log("UniswapV3Adapter deployed at:", address(uniswapV3Adapter));
        deployments.push(Deployment("UniswapV3Adapter", address(uniswapV3Adapter)));

        // Transfer ownership of all adapters to VaultManager
        // This is critical: VaultManager needs to own adapters to call their onlyOwner functions
        aaveAdapter.transferOwnership(address(manager));
        uniswapV2Adapter.transferOwnership(address(manager));
        uniswapV3Adapter.transferOwnership(address(manager));
        console.log("Adapter ownership transferred to VaultManager");
    }

    /**
     * @notice Create vaults
     */
    function _createVaults() internal {
        console.log("\n--- Creating Vaults ---");

        // Create USDC vault using factory
        usdcVault = vaultFactory.createVault(
            usdc,
            string.concat("Vault Guardian ", usdc.name()),
            string.concat("vg", usdc.symbol()),
            1000 // 10% fee
        );
        console.log("USDC vault address:", usdcVault);
        deployments.push(Deployment("USDCVault", usdcVault));
        manager.addVault(usdc, usdcVault);

        // Create USDT vault using factory
        usdtVault = vaultFactory.createVault(
            usdt,
            string.concat("Vault Guardian ", usdt.name()),
            string.concat("vg", usdt.symbol()),
            1000 // 10% fee
        );
        console.log("USDT vault address:", usdtVault);
        deployments.push(Deployment("USDTVault", usdtVault));
        manager.addVault(usdt, usdtVault);

        // Create ETH vault directly (using VaultSharesETH - only one needed)
        VaultSharesETH ethVaultContract = new VaultSharesETH(
            IVaultShares.ConstructorData({
                asset: weth,
                Fee: 1000,
                vaultName: "Vault Guardian ETH",
                vaultSymbol: "vgETH"
            })
        );
        ethVault = address(ethVaultContract);
        console.log("ETH vault address:", ethVault);
        deployments.push(Deployment("ETHVault", ethVault));

        // Transfer ownership of ETH vault to manager
        ethVaultContract.transferOwnership(address(manager));

        // Add ETH vault to manager
        manager.addVault(weth, ethVault);
    }

    /**
     * @notice Configure system
     */
    function _configureSystem() internal {
        console.log("\n--- Configuring System ---");

        // 1. Add adapters to manager
        manager.addAdapter(IProtocolAdapter(address(aaveAdapter)));
        manager.addAdapter(IProtocolAdapter(address(uniswapV2Adapter)));
        manager.addAdapter(IProtocolAdapter(address(uniswapV3Adapter)));
        console.log("All adapters added to manager");

        // 2. Configure Aave adapter for all tokens
        _configureAaveForToken(usdc, usdcVault);
        _configureAaveForToken(usdt, usdtVault);
        _configureAaveForToken(weth, ethVault);
        console.log("Aave adapter configured for all tokens");

        // 3. Configure UniswapV2 adapter for tokens
        _configureUniswapV2ForToken(usdc, usdcVault);
        _configureUniswapV2ForToken(usdt, usdtVault);
        console.log("UniswapV2 adapter configured for tokens");

        // 4. Configure UniswapV3 adapter for tokens
        _configureUniswapV3ForToken(usdc, usdcVault);
        _configureUniswapV3ForToken(usdt, usdtVault);
        _configureUniswapV3ForETH(weth, ethVault);
        console.log("UniswapV3 adapter configured for tokens");

        // 5. Set initial asset allocation for vaults
        _setAssetAllocation(usdc, usdcVault);
        _setAssetAllocation(usdt, usdtVault);
        _setAssetAllocationForETH(weth, ethVault);
        console.log("Asset allocation set for vaults");
    }

    /**
     * @notice Configure Aave adapter for a specific token
     */
    function _configureAaveForToken(IERC20 token, address vault) internal {
        mockAavePool.createAToken(address(token));
        mockAavePool.setReserveNormalizedIncome(address(token), 1e27);

        // Call setTokenVault via VaultManager.execute()
        // ABI encode: setTokenVault(IERC20 token, address vault)
        bytes memory data = abi.encodeWithSignature("setTokenVault(address,address)", address(token), vault);
        manager.execute(0, 0, data); // Aave adapter index = 0
    }

    /**
     * @notice Configure UniswapV2 adapter for a specific token
     */
    function _configureUniswapV2ForToken(MockToken token, address vault) internal {
        address pairAddress;
        if (mockUniswapV2Factory.getPair(address(token), address(weth)) == address(0)) {
            pairAddress = mockUniswapV2Factory.createPair(address(token), address(weth));
        } else {
            pairAddress = mockUniswapV2Factory.getPair(address(token), address(weth));
        }

        // Add initial liquidity to pair
        _addInitialLiquidityToPair(pairAddress, token);

        // Call setTokenConfig via VaultManager.execute()
        // ABI encode: setTokenConfig(IERC20 token, uint256 slippageTolerance, IERC20 counterPartyToken, address VaultAddress)
        bytes memory data = abi.encodeWithSignature(
            "setTokenConfig(address,uint256,address,address)",
            address(token),
            5000, // 50% slippage - 非常宽松的滑点设置
            address(weth),
            vault
        );
        manager.execute(1, 0, data); // UniswapV2 adapter index = 1
    }

    /**
     * @notice Configure UniswapV3 adapter for a specific token
     */
    function _configureUniswapV3ForToken(MockToken token, address vault) internal {
        // Call setTokenConfig via VaultManager.execute()
        // ABI encode: setTokenConfig(IERC20 token, IERC20 counterPartyToken, uint256 slippageTolerance, uint24 feeTier, int24 tickLower, int24 tickUpper, address VaultAddress)
        bytes memory data = abi.encodeWithSignature(
            "setTokenConfig(address,address,uint256,uint24,int24,int24,address)",
            address(token),
            address(weth),
            5000, // 50% slippage - 非常宽松的滑点设置
            3000, // 0.3% fee tier
            -600, // tick lower
            600, // tick upper
            vault
        );
        manager.execute(2, 0, data); // UniswapV3 adapter index = 2
    }

    /**
     * @notice Configure UniswapV3 adapter for ETH vault
     */
    function _configureUniswapV3ForETH(MockWETH9 token, address vault) internal {
        // Call setTokenConfig via VaultManager.execute()
        // ABI encode: setTokenConfig(IERC20 token, IERC20 counterPartyToken, uint256 slippageTolerance, uint24 feeTier, int24 tickLower, int24 tickUpper, address VaultAddress)
        bytes memory data = abi.encodeWithSignature(
            "setTokenConfig(address,address,uint256,uint24,int24,int24,address)",
            address(token),
            address(usdc), // ETH 使用 USDC 作为交易对
            5000, // 50% slippage - 非常宽松的滑点设置
            3000, // 0.3% fee tier
            -600, // tick lower
            600, // tick upper
            vault
        );
        manager.execute(2, 0, data); // UniswapV3 adapter index = 2
    }

    /**
     * @notice Set asset allocation for a specific token
     */
    function _setAssetAllocation(MockToken token, address) internal {
        uint256[] memory adapterIndices = new uint256[](3);
        adapterIndices[0] = 0; // Aave
        adapterIndices[1] = 1; // UniswapV2
        adapterIndices[2] = 2; // UniswapV3

        uint256[] memory allocationData = new uint256[](3);
        allocationData[0] = 500; // 50% to Aave
        allocationData[1] = 300; // 30% to UniswapV2
        allocationData[2] = 200; // 20% to UniswapV3

        manager.updateHoldingAllocation(token, adapterIndices, allocationData);
    }

    /**
     * @notice Set asset allocation for ETH vault (Aave + UniswapV3)
     */
    function _setAssetAllocationForETH(MockWETH9 token, address) internal {
        uint256[] memory adapterIndices = new uint256[](2);
        adapterIndices[0] = 0; // Aave
        adapterIndices[1] = 2; // UniswapV3

        uint256[] memory allocationData = new uint256[](2);
        allocationData[0] = 500; // 50% to Aave
        allocationData[1] = 500; // 50% to UniswapV3

        manager.updateHoldingAllocation(token, adapterIndices, allocationData);
    }

    /**
     * @notice Add initial liquidity to UniswapV2 pair
     */
    function _addInitialLiquidityToPair(address pairAddress, MockToken token) internal {
        // Mint tokens to deployer for adding liquidity
        // Increased to 10M to support larger vault deposits
        uint256 liquidityAmount = 10000000 * 10 ** 18; // 10M tokens
        token.mint(deployer, liquidityAmount);
        weth.mint(deployer, liquidityAmount);

        // Transfer tokens to pair
        token.transfer(pairAddress, liquidityAmount);
        weth.transfer(pairAddress, liquidityAmount);

        // Add initial liquidity
        MockUniswapV2Pair(pairAddress).mint(deployer);
    }

    /**
     * @notice Output deployment information
     */
    function _logDeploymentInfo() internal view {
        console.log("\n=== Deployment Summary ===");
        console.log("VaultFactory address:", address(vaultFactory));
        console.log("VaultImplementation address:", address(vaultImplementation));
        console.log("Manager address:", address(manager));

        console.log("\n--- Token Addresses ---");
        console.log("USDC token address:", address(usdc));
        console.log("USDT token address:", address(usdt));
        console.log("WETH token address:", address(weth));

        console.log("\n--- Vault Addresses ---");
        console.log("USDC vault address:", usdcVault);
        console.log("USDT vault address:", usdtVault);
        console.log("ETH vault address:", ethVault);

        console.log("\n--- Adapter Addresses ---");
        console.log("Aave adapter address:", address(aaveAdapter));
        console.log("UniswapV2 adapter address:", address(uniswapV2Adapter));
        console.log("UniswapV3 adapter address:", address(uniswapV3Adapter));

        console.log("\n=== Usage Instructions ===");
        console.log("1. Create more vaults using VaultFactory.createVault()");
        console.log("2. Deposit and invest through vault addresses");
        console.log("3. Interact with DeFi protocols directly through adapter addresses");
        console.log("4. All contract addresses saved to deployments/ directory");
        console.log("\n=== Available Vaults ===");
        console.log("- USDC Vault: Stablecoin vault for USDC deposits");
        console.log("- USDT Vault: Stablecoin vault for USDT deposits");
        console.log("- ETH Vault: Ethereum vault for ETH deposits");
    }

    /**
     * @notice Add initial liquidity to UniswapV3 pool
     */
    function _addInitialLiquidityToUniswapV3Pool(address poolAddress, IERC20 token0, IERC20 token1) internal {
        console.log("Adding liquidity to pool:", poolAddress);

        // Mint tokens to deployer for adding liquidity
        // Increased to 10M to support larger vault deposits
        uint256 liquidityAmount = 10000000 * 10 ** 18;

        // Use low-level call for tokens that may be MockToken or MockWETH9
        (bool success0,) =
            address(token0).call(abi.encodeWithSignature("mint(address,uint256)", deployer, liquidityAmount));
        require(success0, "Token0 mint failed");
        console.log("Token0 minted:", liquidityAmount);

        (bool success1,) =
            address(token1).call(abi.encodeWithSignature("mint(address,uint256)", deployer, liquidityAmount));
        require(success1, "Token1 mint failed");
        console.log("Token1 minted:", liquidityAmount);

        // Approve position manager to spend tokens
        token0.approve(address(realisticPositionManager), liquidityAmount);
        token1.approve(address(realisticPositionManager), liquidityAmount);
        console.log("Tokens approved for position manager");

        // Create mint params using the struct from RealisticNonfungiblePositionManager
        RealisticNonfungiblePositionManager.MintParams memory params = RealisticNonfungiblePositionManager.MintParams({
            token0: address(token0),
            token1: address(token1),
            fee: 3000,
            tickLower: -887200, // Near full range (valid tick spacing for fee tier 3000)
            tickUpper: 887200, // Near full range
            amount0Desired: liquidityAmount,
            amount1Desired: liquidityAmount,
            amount0Min: 0,
            amount1Min: 0,
            recipient: deployer,
            deadline: block.timestamp + 1000
        });

        // Add liquidity to pool
        (uint256 tokenId, uint128 liquidity,,) = realisticPositionManager.mint(params);
        console.log("Liquidity added - TokenId:", tokenId, "Liquidity:", liquidity);
    }

    /**
     * @notice Transfer VaultManager ownership to admin
     */
    function _transferOwnershipToAdmin() internal {
        console.log("\n--- Transferring Ownership to Admin ---");

        address admin = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;

        console.log("Current manager owner:", manager.owner());
        console.log("Transferring to admin:", admin);

        manager.transferOwnership(admin);

        console.log("Ownership transferred successfully!");
        console.log("New manager owner:", manager.owner());
        console.log("\nIMPORTANT: Update backend .env with admin private key:");
        console.log("PRIVATE_KEY=47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a");
    }
}
