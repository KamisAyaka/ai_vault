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
    MockToken public usdc;
    MockWETH9 public weth;

    // 金库合约
    address public usdcVault;
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

        console.log("=== AI Vault System Deployment Completed ===");
    }

    /**
     * @notice Deploy token contracts
     */
    function _deployTokens() internal {
        console.log("\n--- Deploying Token Contracts ---");

        usdc = new MockToken("USD Coin", "USDC");
        console.log("USDC deployed at:", address(usdc));

        weth = new MockWETH9();
        console.log("WETH deployed at:", address(weth));

        // Mint tokens to deployer for testing
        usdc.mint(deployer, 1000000 * 10 ** 18);
        // WETH doesn't need minting - it's created through deposit()

        console.log(
            "Deployer USDC balance:",
            usdc.balanceOf(deployer) / 10 ** 18
        );
        console.log(
            "Deployer WETH balance:",
            weth.balanceOf(deployer) / 10 ** 18
        );
    }

    /**
     * @notice Deploy manager contract
     */
    function _deployManager() internal {
        console.log("\n--- Deploying Manager Contract ---");

        manager = new AIAgentVaultManager(); // 不再需要 WETH 参数
        console.log("Manager deployed at:", address(manager));

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
        console.log(
            "VaultImplementation deployed at:",
            address(vaultImplementation)
        );
        deployments.push(
            Deployment("VaultImplementation", address(vaultImplementation))
        );

        // Deploy factory contract
        vaultFactory = new VaultFactory(
            address(vaultImplementation),
            address(manager)
        );
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

        // Mint USDC to MockAavePool for divestment
        usdc.mint(address(mockAavePool), 1000000 * 10 ** 18);

        // UniswapV2 Mock
        mockUniswapV2Factory = new MockUniswapV2Factory();
        mockUniswapV2Router = new MockUniswapV2Router(
            address(mockUniswapV2Factory)
        );
        console.log(
            "MockUniswapV2Factory deployed at:",
            address(mockUniswapV2Factory)
        );
        console.log(
            "MockUniswapV2Router deployed at:",
            address(mockUniswapV2Router)
        );

        // UniswapV3 Mock
        realisticUniswapV3Factory = new RealisticUniswapV3Factory();
        address poolAddress = realisticUniswapV3Factory.createPool(
            address(usdc),
            address(weth),
            3000
        );
        console.log(
            "RealisticUniswapV3Factory deployed at:",
            address(realisticUniswapV3Factory)
        );
        console.log("USDC/WETH pool address:", poolAddress);

        // Mint tokens to pool for swapping
        usdc.mint(poolAddress, 1000000 * 10 ** 18);
        weth.mint(poolAddress, 1000000 * 10 ** 18);

        realisticUniswapV3Router = new RealisticSwapRouter(poolAddress);
        realisticPositionManager = new RealisticNonfungiblePositionManager();
        realisticQuoter = new RealisticQuoter(poolAddress);

        // Set factory reference for position manager
        realisticPositionManager.setFactory(address(realisticUniswapV3Factory));

        // Mint tokens to RealisticNonfungiblePositionManager for divestment
        usdc.mint(address(realisticPositionManager), 1000000 * 10 ** 18);
        weth.mint(address(realisticPositionManager), 1000000 * 10 ** 18);

        console.log(
            "RealisticSwapRouter deployed at:",
            address(realisticUniswapV3Router)
        );
        console.log(
            "RealisticPositionManager deployed at:",
            address(realisticPositionManager)
        );
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
        uniswapV2Adapter = new UniswapV2Adapter(
            address(mockUniswapV2Router),
            address(mockUniswapV2Factory)
        );
        console.log("UniswapV2Adapter deployed at:", address(uniswapV2Adapter));
        deployments.push(
            Deployment("UniswapV2Adapter", address(uniswapV2Adapter))
        );

        // Deploy UniswapV3 adapter
        uniswapV3Adapter = new UniswapV3Adapter(
            address(realisticUniswapV3Router),
            address(realisticPositionManager),
            address(realisticUniswapV3Factory),
            address(realisticQuoter)
        );
        console.log("UniswapV3Adapter deployed at:", address(uniswapV3Adapter));
        deployments.push(
            Deployment("UniswapV3Adapter", address(uniswapV3Adapter))
        );
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

        // USDC vault ownership is already transferred to manager during creation

        // Add USDC vault to manager
        manager.addVault(usdc, usdcVault);

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

        // 2. Configure Aave adapter
        mockAavePool.createAToken(address(usdc));
        mockAavePool.setReserveNormalizedIncome(address(usdc), 1e27);
        aaveAdapter.setTokenVault(IERC20(address(usdc)), usdcVault);
        console.log("Aave adapter configured");

        // 3. Configure UniswapV2 adapter
        address pairAddress;
        if (
            mockUniswapV2Factory.getPair(address(usdc), address(weth)) ==
            address(0)
        ) {
            pairAddress = mockUniswapV2Factory.createPair(
                address(usdc),
                address(weth)
            );
        } else {
            pairAddress = mockUniswapV2Factory.getPair(
                address(usdc),
                address(weth)
            );
        }

        // Add initial liquidity to pair
        _addInitialLiquidityToPair(pairAddress);

        uniswapV2Adapter.setTokenConfig(
            IERC20(address(usdc)),
            5000, // 50% slippage - 非常宽松的滑点设置
            IERC20(address(weth)),
            usdcVault
        );
        console.log("UniswapV2 adapter configured, pair address:", pairAddress);

        // 4. Configure UniswapV3 adapter
        uniswapV3Adapter.setTokenConfig(
            IERC20(address(usdc)),
            IERC20(address(weth)),
            5000, // 50% slippage - 非常宽松的滑点设置
            3000, // 0.3% fee tier
            -600, // tick lower
            600, // tick upper
            usdcVault
        );
        console.log("UniswapV3 adapter configured");

        // 5. Set initial asset allocation
        uint256[] memory adapterIndices = new uint256[](3);
        adapterIndices[0] = 0; // Aave
        adapterIndices[1] = 1; // UniswapV2
        adapterIndices[2] = 2; // UniswapV3

        uint256[] memory allocationData = new uint256[](3);
        allocationData[0] = 500; // 50% to Aave
        allocationData[1] = 300; // 30% to UniswapV2
        allocationData[2] = 200; // 20% to UniswapV3

        manager.updateHoldingAllocation(usdc, adapterIndices, allocationData);
        console.log(
            "Initial asset allocation set: Aave 50%, UniswapV2 30%, UniswapV3 20%"
        );
    }

    /**
     * @notice Add initial liquidity to UniswapV2 pair
     */
    function _addInitialLiquidityToPair(address pairAddress) internal {
        // Mint tokens to deployer for adding liquidity
        uint256 liquidityAmount = 100000 * 10 ** 18; // 100000 tokens
        usdc.mint(deployer, liquidityAmount);
        weth.mint(deployer, liquidityAmount);

        // Transfer tokens to pair
        usdc.transfer(pairAddress, liquidityAmount);
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
        console.log(
            "VaultImplementation address:",
            address(vaultImplementation)
        );
        console.log("Manager address:", address(manager));
        console.log("USDC token address:", address(usdc));
        console.log("WETH token address:", address(weth));
        console.log("USDC vault address:", usdcVault);
        console.log("ETH vault address:", ethVault);
        console.log("Aave adapter address:", address(aaveAdapter));
        console.log("UniswapV2 adapter address:", address(uniswapV2Adapter));
        console.log("UniswapV3 adapter address:", address(uniswapV3Adapter));
        console.log("\n=== Usage Instructions ===");
        console.log("1. Create more vaults using VaultFactory.createVault()");
        console.log("2. Deposit and invest through vault addresses");
        console.log(
            "3. Interact with DeFi protocols directly through adapter addresses"
        );
        console.log(
            "4. All contract addresses saved to deployments/ directory"
        );
    }

    /**
     * @notice Get deployed contract addresses (for other scripts to call)
     */
    function getDeployedAddresses()
        external
        view
        returns (
            address _vaultFactory,
            address _vaultImplementation,
            address _manager,
            address _usdc,
            address _weth,
            address _usdcVault,
            address _ethVault,
            address _aaveAdapter,
            address _uniswapV2Adapter,
            address _uniswapV3Adapter
        )
    {
        return (
            address(vaultFactory),
            address(vaultImplementation),
            address(manager),
            address(usdc),
            address(weth),
            usdcVault,
            ethVault,
            address(aaveAdapter),
            address(uniswapV2Adapter),
            address(uniswapV3Adapter)
        );
    }
}
