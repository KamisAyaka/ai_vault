// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol";
import "./mock/MockToken.sol";
import "./mock/MockUniswapV3.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UniswapV3AdapterTest is Test {
    UniswapV3Adapter public adapter;
    MockSwapRouter public mockRouter;
    MockNonfungiblePositionManager public mockPositionManager;
    MockUniswapV3Factory public mockFactory;
    MockQuoter public mockQuoter;
    MockToken public tokenA;
    MockToken public tokenB;
    address public owner;
    address public vault;

    event TokenConfigUpdated(address indexed token);
    event UniswapV3Invested(
        address indexed token,
        uint256 tokenAmount,
        uint256 counterPartyTokenAmount,
        uint256 liquidity
    );
    event UniswapV3Divested(address indexed token, uint256 tokenAmount);
    event LiquidityPositionCreated(
        address indexed vault,
        uint256 indexed tokenId
    );

    function setUp() public {
        owner = address(this);
        vault = address(0x123);

        // Deploy mock tokens (ensure tokenA < tokenB for proper ordering)
        // Deploy in specific order to ensure tokenA < tokenB
        tokenA = new MockToken("A Token", "ATKN"); // Address will be lower
        tokenB = new MockToken("B Token", "BTKN"); // Address will be higher

        // Mint tokens to vault
        tokenA.mint(vault, 1000 * 10 ** 18);
        tokenB.mint(vault, 1000 * 10 ** 18);

        // Deploy mock Uniswap V3 contracts
        mockPositionManager = new MockNonfungiblePositionManager();
        mockFactory = new MockUniswapV3Factory();

        // Create pool with correct token order
        address poolAddress = mockFactory.createPool(
            address(tokenA),
            address(tokenB),
            3000
        ); // 0.3% fee tier

        mockRouter = new MockSwapRouter(poolAddress);
        mockQuoter = new MockQuoter(poolAddress);

        // Deploy adapter
        adapter = new UniswapV3Adapter(
            address(mockRouter),
            address(mockPositionManager),
            address(mockFactory),
            address(mockQuoter)
        );

        // Set token config
        vm.prank(owner);
        adapter.setTokenConfig(
            IERC20(address(tokenA)),
            IERC20(address(tokenB)),
            100, // 1% slippage tolerance
            3000, // 0.3% fee tier
            -600, // tick lower
            600, // tick upper
            vault
        );
    }

    function testSetTokenConfig() public {
        // Test that owner can set token config
        vm.prank(owner);
        adapter.setTokenConfig(
            IERC20(address(tokenB)),
            IERC20(address(tokenA)),
            200, // 2% slippage tolerance
            10000, // 1% fee tier
            -1200, // tick lower
            1200, // tick upper
            vault
        );

        // Check that config was set correctly
        UniswapV3Adapter.TokenConfig memory config = adapter.getTokenConfig(
            IERC20(address(tokenB))
        );
        assertEq(address(config.counterPartyToken), address(tokenA));
        assertEq(config.slippageTolerance, 200);
        assertEq(config.feeTier, 10000);
        assertEq(config.tickLower, -1200);
        assertEq(config.tickUpper, 1200);
        assertEq(config.VaultAddress, vault);

        // Test that non-owner cannot set token config
        vm.prank(address(0x456));
        vm.expectRevert();
        adapter.setTokenConfig(
            IERC20(address(tokenA)),
            IERC20(address(tokenB)),
            300,
            3000,
            -600,
            600,
            vault
        );
    }

    function testUpdateTokenSlippageTolerance() public {
        // Test that owner can update slippage tolerance
        vm.prank(owner);
        adapter.UpdateTokenSlippageTolerance(IERC20(address(tokenA)), 200);

        // Check that slippage tolerance was updated
        UniswapV3Adapter.TokenConfig memory config = adapter.getTokenConfig(
            IERC20(address(tokenA))
        );
        assertEq(config.slippageTolerance, 200);

        // Test that non-owner cannot update slippage tolerance
        vm.prank(address(0x456));
        vm.expectRevert();
        adapter.UpdateTokenSlippageTolerance(IERC20(address(tokenA)), 300);
    }

    function testInvest() public {
        uint256 amount0Desired = 100e18;
        vm.startPrank(vault);
        tokenA.approve(address(adapter), amount0Desired);
        vm.stopPrank();

        // Test that vault can invest
        vm.prank(vault);
        uint256 investedAmount = adapter.invest(
            IERC20(address(tokenA)),
            100 * 10 ** 18
        );

        assertEq(investedAmount, 100 * 10 ** 18);

        // Check that tokens were transferred from vault
        assertEq(tokenA.balanceOf(vault), 900 * 10 ** 18);
    }

    function testInvestFromNonVault() public {
        // Test that non-vault cannot invest
        vm.prank(address(0x456));
        vm.expectRevert(
            abi.encodeWithSelector(
                UniswapV3Adapter.OnlyVaultCanCallThisFunction.selector
            )
        );
        adapter.invest(IERC20(address(tokenA)), 100 * 10 ** 18);
    }

    function testDivest() public {
        // First invest
        uint256 amount0Desired = 100e18;
        vm.startPrank(vault);
        tokenA.approve(address(adapter), amount0Desired);
        vm.stopPrank();

        // Test that vault can invest
        vm.prank(vault);
        adapter.invest(IERC20(address(tokenA)), 100 * 10 ** 18);

        // Seed pool with token balances so mock swap has liquidity to pay out
        address token0 = address(tokenA) < address(tokenB)
            ? address(tokenA)
            : address(tokenB);
        address token1 = address(tokenA) < address(tokenB)
            ? address(tokenB)
            : address(tokenA);
        address poolAddr = mockFactory.getPool(token0, token1, 3000);
        vm.prank(vault);
        tokenA.transfer(poolAddr, 100 * 10 ** 18);
        vm.prank(vault);
        tokenB.transfer(poolAddr, 100 * 10 ** 18);

        // Seed position manager with balances so mock decreaseLiquidity can pay out
        vm.prank(vault);
        tokenA.transfer(address(mockPositionManager), 100 * 10 ** 18);
        vm.prank(vault);
        tokenB.transfer(address(mockPositionManager), 100 * 10 ** 18);

        // Test that vault can divest
        vm.prank(vault);
        uint256 divestedAmount = adapter.divest(
            IERC20(address(tokenA)),
            50 * 10 ** 18
        );

        // Check that tokens were transferred back to vault
        assertGt(divestedAmount, 0);
    }

    function testDivestFromNonVault() public {
        // Test that non-vault cannot divest
        vm.prank(address(0x456));
        vm.expectRevert(
            abi.encodeWithSelector(
                UniswapV3Adapter.OnlyVaultCanCallThisFunction.selector
            )
        );
        adapter.divest(IERC20(address(tokenA)), 100 * 10 ** 18);
    }

    function testGetTotalValue() public {
        // Initially should be 0
        assertEq(adapter.getTotalValue(IERC20(address(tokenA))), 0);

        // After investing
        vm.prank(vault);
        tokenA.approve(address(adapter), 100 * 10 ** 18);
        tokenB.approve(address(adapter), 100 * 10 ** 18);

        // Also transfer some tokenB to adapter to simulate having both tokens
        vm.prank(vault);
        tokenB.transfer(address(adapter), 50 * 10 ** 18);

        vm.prank(vault);
        adapter.invest(IERC20(address(tokenA)), 100 * 10 ** 18);

        // Should have some value
        uint256 totalValue = adapter.getTotalValue(IERC20(address(tokenA)));
        assertGt(totalValue, 0);
    }

    function testGetName() public view {
        assertEq(adapter.getName(), "UniswapV3");
    }
}
