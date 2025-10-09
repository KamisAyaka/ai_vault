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

/**
 * @title DeploySepoliaAIVault
 * @notice Deploy AI Vault system to Sepolia testnet using real Aave, Uniswap V2 and V3 contracts
 * @dev Uses deployed DeFi protocol contracts on Sepolia
 *
 * Usage:
 * forge script script/DeploySepoliaAIVault.s.sol --rpc-url sepolia --broadcast --verify
 */
contract DeploySepoliaAIVault is ScaffoldETHDeploy {
    // 核心合约
    AIAgentVaultManager public manager;
    VaultFactory public vaultFactory;
    VaultImplementation public vaultImplementation;

    // Sepolia 测试网上的真实代币地址
    IERC20 public constant WETH = IERC20(0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14); // Sepolia WETH
    IERC20 public constant USDC = IERC20(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8); // Sepolia USDC
    IERC20 public constant USDT = IERC20(0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0); // Sepolia USDT
    IERC20 public constant WBTC = IERC20(0x29f2D40B0605204364af54EC677bD022dA425d03); // Sepolia WBTC

    // Sepolia 上的 Aave V3 合约地址
    address public constant AAVE_POOL = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;

    // Sepolia 上的 Uniswap V2 合约地址
    address public constant UNISWAP_V2_FACTORY = 0xF62c03E08ada871A0bEb309762E260a7a6a880E6;
    address public constant UNISWAP_V2_ROUTER = 0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3;

    // Sepolia 上的 Uniswap V3 合约地址
    address public constant UNISWAP_V3_FACTORY = 0x0227628f3F023bb0B980b67D528571c95c6DaC1c;
    address public constant UNISWAP_V3_ROUTER = 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E; // SwapRouter02
    address public constant UNISWAP_V3_POSITION_MANAGER = 0x1238536071E1c677A632429e3655c799b22cDA52;
    address public constant UNISWAP_V3_QUOTER = 0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3; // QuoterV2

    // 金库合约
    address public wethVault;
    address public usdcVault;
    address public usdtVault;
    address public wbtcVault;

    // 适配器合约
    AaveAdapter public aaveAdapter;
    UniswapV2Adapter public uniswapV2Adapter;
    UniswapV3Adapter public uniswapV3Adapter;

    /**
     * @notice Main deployment function
     * @dev Deploy all contracts in order and configure them
     */
    function run() external ScaffoldEthDeployerRunner {
        console.log("=== Starting AI Vault System Deployment on Sepolia ===");
        console.log("Deployer address:", deployer);
        console.log("Chain ID:", block.chainid);

        require(block.chainid == 11155111, "Must deploy to Sepolia (chainid 11155111)");

        // 1. Deploy manager
        _deployManager();

        // 2. Deploy factory and implementation
        _deployFactory();

        // 3. Deploy adapters
        _deployAdapters();

        // 4. Create vaults
        _createVaults();

        // 5. Configure system
        _configureSystem();

        // 6. Output deployment info
        _logDeploymentInfo();

        console.log("=== AI Vault System Deployment on Sepolia Completed ===");
    }

    /**
     * @notice Deploy manager contract
     */
    function _deployManager() internal {
        console.log("\n--- Deploying Manager Contract ---");

        manager = new AIAgentVaultManager();
        console.log("Manager deployed at:", address(manager));
        console.log("Manager owner:", manager.owner());

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
     * @notice Deploy adapter contracts
     */
    function _deployAdapters() internal {
        console.log("\n--- Deploying Adapter Contracts ---");

        // Deploy Aave adapter with Sepolia addresses
        aaveAdapter = new AaveAdapter(AAVE_POOL);
        console.log("AaveAdapter deployed at:", address(aaveAdapter));
        deployments.push(Deployment("AaveAdapter", address(aaveAdapter)));

        // Deploy UniswapV2 adapter with Sepolia addresses
        uniswapV2Adapter = new UniswapV2Adapter(UNISWAP_V2_ROUTER, UNISWAP_V2_FACTORY);
        console.log("UniswapV2Adapter deployed at:", address(uniswapV2Adapter));
        deployments.push(Deployment("UniswapV2Adapter", address(uniswapV2Adapter)));

        // Deploy UniswapV3 adapter with Sepolia addresses
        uniswapV3Adapter = new UniswapV3Adapter(UNISWAP_V3_ROUTER, UNISWAP_V3_POSITION_MANAGER, UNISWAP_V3_FACTORY);
        console.log("UniswapV3Adapter deployed at:", address(uniswapV3Adapter));
        deployments.push(Deployment("UniswapV3Adapter", address(uniswapV3Adapter)));

        // Transfer ownership to VaultManager
        aaveAdapter.transferOwnership(address(manager));
        uniswapV2Adapter.transferOwnership(address(manager));
        uniswapV3Adapter.transferOwnership(address(manager));
        console.log("All adapters ownership transferred to VaultManager");
    }

    /**
     * @notice Create vaults
     */
    function _createVaults() internal {
        console.log("\n--- Creating Vaults ---");

        // Create WETH vault
        VaultSharesETH wethVaultContract = new VaultSharesETH(
            IVaultShares.ConstructorData({
                asset: WETH,
                Fee: 100, // 10% fee
                vaultName: "Vault Guardian WETH",
                vaultSymbol: "vgWETH"
            })
        );
        wethVault = address(wethVaultContract);
        console.log("WETH vault address:", wethVault);
        deployments.push(Deployment("WETHVault", wethVault));

        // Transfer ownership and add to manager
        wethVaultContract.transferOwnership(address(manager));
        manager.addVault(WETH, wethVault);

        // Create USDC vault using factory
        usdcVault = vaultFactory.createVault(
            USDC,
            "Vault Guardian USDC",
            "vgUSDC",
            100 // 1% fee
        );
        console.log("USDC vault address:", usdcVault);
        deployments.push(Deployment("USDCVault", usdcVault));
        // Factory already set owner to manager, just add to manager
        manager.addVault(USDC, usdcVault);

        // Create USDT vault using factory
        usdtVault = vaultFactory.createVault(
            USDT,
            "Vault Guardian USDT",
            "vgUSDT",
            100 // 1% fee
        );
        console.log("USDT vault address:", usdtVault);
        deployments.push(Deployment("USDTVault", usdtVault));
        // Factory already set owner to manager, just add to manager
        manager.addVault(USDT, usdtVault);

        // Create WBTC vault using factory
        wbtcVault = vaultFactory.createVault(
            WBTC,
            "Vault Guardian WBTC",
            "vgWBTC",
            100 // 1% fee
        );
        console.log("WBTC vault address:", wbtcVault);
        deployments.push(Deployment("WBTCVault", wbtcVault));
        // Factory already set owner to manager, just add to manager
        manager.addVault(WBTC, wbtcVault);
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
        console.log("Aave, UniswapV2 and UniswapV3 adapters added to manager");

        // 2. Configure Aave adapter for all tokens
        _configureAaveForToken(WETH, wethVault);
        _configureAaveForToken(USDC, usdcVault);
        _configureAaveForToken(USDT, usdtVault);
        _configureAaveForToken(WBTC, wbtcVault);
        console.log("Aave adapter configured for all tokens");

        // 3. Configure UniswapV2 adapter for tokens
        _configureUniswapV2ForToken(WETH, USDC, wethVault);
        _configureUniswapV2ForToken(USDC, WETH, usdcVault);
        _configureUniswapV2ForToken(USDT, WETH, usdtVault);
        _configureUniswapV2ForToken(WBTC, USDC, wbtcVault);
        console.log("UniswapV2 adapter configured for all tokens");

        // 4. Configure UniswapV3 adapter for tokens
        _configureUniswapV3ForToken(WETH, USDC, wethVault);
        _configureUniswapV3ForToken(USDC, WETH, usdcVault);
        _configureUniswapV3ForToken(USDT, WETH, usdtVault);
        _configureUniswapV3ForToken(WBTC, USDC, wbtcVault);
        console.log("UniswapV3 adapter configured for all tokens");

        // 5. Set asset allocation for vaults
        _setAssetAllocation(WETH);
        _setAssetAllocation(USDC);
        _setAssetAllocation(USDT);
        _setAssetAllocation(WBTC);
        console.log("Asset allocation set for vaults");
    }

    /**
     * @notice Configure Aave adapter for a specific token
     */
    function _configureAaveForToken(IERC20 token, address vault) internal {
        // ABI encode: setTokenVault(IERC20 token, address vault)
        bytes memory data = abi.encodeWithSignature("setTokenVault(address,address)", address(token), vault);
        manager.execute(0, 0, data); // Aave adapter index = 0
    }

    /**
     * @notice Configure UniswapV2 adapter for a specific token
     */
    function _configureUniswapV2ForToken(IERC20 token, IERC20 counterPartyToken, address vault) internal {
        // ABI encode: setTokenConfig(IERC20 token, uint256 slippageTolerance, IERC20 counterPartyToken, address VaultAddress)
        bytes memory data = abi.encodeWithSignature(
            "setTokenConfig(address,uint256,address,address)",
            address(token),
            500, // 5% slippage tolerance
            address(counterPartyToken),
            vault
        );
        manager.execute(1, 0, data); // UniswapV2 adapter index = 1
    }

    /**
     * @notice Configure UniswapV3 adapter for a specific token
     */
    function _configureUniswapV3ForToken(IERC20 token, IERC20 counterPartyToken, address vault) internal {
        // ABI encode: setTokenConfig(IERC20 token, IERC20 counterPartyToken, uint256 slippageTolerance, uint24 feeTier, int24 tickLower, int24 tickUpper, address VaultAddress)
        bytes memory data = abi.encodeWithSignature(
            "setTokenConfig(address,address,uint256,uint24,int24,int24,address)",
            address(token),
            address(counterPartyToken),
            500, // 5% slippage tolerance
            3000, // 0.3% fee tier
            59400, // tick lower - 更合理的价格区间
            60600, // tick upper - 更合理的价格区间
            vault
        );
        manager.execute(2, 0, data); // UniswapV3 adapter index = 2
    }

    /**
     * @notice Set asset allocation for a specific token
     */
    function _setAssetAllocation(IERC20 token) internal {
        uint256[] memory adapterIndices = new uint256[](3);
        adapterIndices[0] = 0; // Aave
        adapterIndices[1] = 1; // UniswapV2
        adapterIndices[2] = 2; // UniswapV3

        uint256[] memory allocationData = new uint256[](3);

        if (token == WETH) {
            // WETH uses Aave and UniswapV3 (no V2 config)
            adapterIndices = new uint256[](2);
            adapterIndices[0] = 0; // Aave
            adapterIndices[1] = 2; // UniswapV3

            allocationData = new uint256[](2);
            allocationData[0] = 500; // 50% to Aave
            allocationData[1] = 500; // 50% to UniswapV3
        } else {
            // USDC, USDT and WBTC use all three adapters
            allocationData[0] = 400; // ~40% to Aave
            allocationData[1] = 300; // ~30% to UniswapV2
            allocationData[2] = 300; // ~30% to UniswapV3
        }

        manager.updateHoldingAllocation(token, adapterIndices, allocationData);
    }

    /**
     * @notice Output deployment information
     */
    function _logDeploymentInfo() internal view {
        console.log("\n=== Deployment Summary ===");
        console.log("Network: Sepolia");
        console.log("VaultFactory address:", address(vaultFactory));
        console.log("VaultImplementation address:", address(vaultImplementation));
        console.log("Manager address:", address(manager));

        console.log("\n--- Token Addresses (Sepolia) ---");
        console.log("WETH token address:", address(WETH));
        console.log("USDC token address:", address(USDC));
        console.log("USDT token address:", address(USDT));
        console.log("WBTC token address:", address(WBTC));

        console.log("\n--- Vault Addresses ---");
        console.log("WETH vault address:", wethVault);
        console.log("USDC vault address:", usdcVault);
        console.log("USDT vault address:", usdtVault);
        console.log("WBTC vault address:", wbtcVault);

        console.log("\n--- Adapter Addresses ---");
        console.log("Aave adapter address:", address(aaveAdapter));
        console.log("UniswapV2 adapter address:", address(uniswapV2Adapter));
        console.log("UniswapV3 adapter address:", address(uniswapV3Adapter));

        console.log("\n--- Aave V3 Contracts (Sepolia) ---");
        console.log("Pool:", AAVE_POOL);

        console.log("\n--- Uniswap V2 Contracts (Sepolia) ---");
        console.log("Factory:", UNISWAP_V2_FACTORY);
        console.log("Router:", UNISWAP_V2_ROUTER);

        console.log("\n--- Uniswap V3 Contracts (Sepolia) ---");
        console.log("Factory:", UNISWAP_V3_FACTORY);
        console.log("SwapRouter:", UNISWAP_V3_ROUTER);
        console.log("PositionManager:", UNISWAP_V3_POSITION_MANAGER);
        console.log("Quoter:", UNISWAP_V3_QUOTER);

        console.log("\n=== Usage Instructions ===");
        console.log("1. Get test WETH from Sepolia faucet or wrap ETH");
        console.log("2. Get test USDC/USDT from Sepolia faucets");
        console.log("3. Deposit tokens to vaults using vault addresses");
        console.log("4. Test Aave, Uniswap V2 and V3 integration with real contracts");
        console.log("5. All contract addresses saved to deployments/ directory");
    }
}
