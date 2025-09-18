// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol";
import "./mock/MockToken.sol";
import "./mock/MockUniswapV2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UniswapV2AdapterTest is Test {
    UniswapV2Adapter public adapter;
    MockUniswapV2Factory public mockFactory;
    MockUniswapV2Router public mockRouter;
    MockToken public tokenA;
    MockToken public tokenB;
    MockUniswapV2Pair public pair;
    address public owner;
    address public vault;

    event TokenConfigUpdated(address indexed token);
    event UniswapInvested(
        address indexed token, uint256 tokenAmount, uint256 counterPartyTokenAmount, uint256 liquidity
    );
    event UniswapDivested(address indexed token, uint256 tokenAmount, uint256 counterPartyTokenAmount);

    function setUp() public {
        owner = address(this);
        vault = address(0x123);

        // Deploy mock tokens
        tokenA = new MockToken("Token A", "TKNA");
        tokenB = new MockToken("Token B", "TKNB");

        // Mint tokens to vault
        tokenA.mint(vault, 1000 * 10 ** 18);
        tokenB.mint(vault, 1000 * 10 ** 18);

        // Deploy mock Uniswap V2 contracts
        mockFactory = new MockUniswapV2Factory();
        mockRouter = new MockUniswapV2Router(address(mockFactory)); // Use tokenB as WETH mock

        // Create pair
        address pairAddress = mockFactory.createPair(address(tokenA), address(tokenB));
        pair = MockUniswapV2Pair(pairAddress);

        // Mint tokens to router for swapping
        tokenB.mint(address(mockRouter), 1000 * 10 ** 18);

        // Mint tokens to pair for initial liquidity
        tokenA.mint(address(pair), 1000 * 10 ** 18);
        tokenB.mint(address(pair), 1000 * 10 ** 18);

        // Initialize pair reserves by calling mint
        vm.prank(address(pair));
        pair.mint(address(0x1)); // Mint to a dummy address to initialize reserves

        // Deploy adapter
        adapter = new UniswapV2Adapter(address(mockRouter));

        // Set token config
        vm.prank(owner);
        adapter.setTokenConfig(
            IERC20(address(tokenA)),
            100, // 1% slippage tolerance
            IERC20(address(tokenB)),
            vault
        );
    }

    function testSetTokenConfig() public {
        // Test that owner can set token config
        vm.prank(owner);
        adapter.setTokenConfig(
            IERC20(address(tokenB)),
            200, // 2% slippage tolerance
            IERC20(address(tokenA)),
            vault
        );

        // Check that config was set correctly
        UniswapV2Adapter.TokenConfig memory config = adapter.getTokenConfig(IERC20(address(tokenB)));
        assertEq(config.slippageTolerance, 200);
        assertEq(address(config.counterPartyToken), address(tokenA));
        assertEq(config.VaultAddress, vault);

        // Test that non-owner cannot set token config
        vm.prank(address(0x456));
        vm.expectRevert();
        adapter.setTokenConfig(IERC20(address(tokenA)), 300, IERC20(address(tokenB)), vault);
    }

    function testUpdateTokenSlippageTolerance() public {
        // Test that owner can update slippage tolerance
        vm.prank(owner);
        adapter.UpdateTokenSlippageTolerance(IERC20(address(tokenA)), 200);

        // Check that slippage tolerance was updated
        UniswapV2Adapter.TokenConfig memory config = adapter.getTokenConfig(IERC20(address(tokenA)));
        assertEq(config.slippageTolerance, 200);

        // Test that non-owner cannot update slippage tolerance
        vm.prank(address(0x456));
        vm.expectRevert();
        adapter.UpdateTokenSlippageTolerance(IERC20(address(tokenA)), 300);
    }

    function testInvest() public {
        // Approve adapter to spend vault's tokens
        vm.prank(vault);
        tokenA.approve(address(adapter), 100 * 10 ** 18);

        // Test that vault can invest
        vm.prank(vault);
        uint256 investedAmount = adapter.invest(IERC20(address(tokenA)), 100 * 10 ** 18);

        assertEq(investedAmount, 100 * 10 ** 18);

        // Check that tokens were transferred from vault
        assertEq(tokenA.balanceOf(vault), 900 * 10 ** 18);

        // Check that LP tokens were minted to adapter
        uint256 lpBalance = pair.balanceOf(address(adapter));
        assertGt(lpBalance, 0);
    }

    function testInvestFromNonVault() public {
        // Test that non-vault cannot invest
        vm.prank(address(0x456));
        vm.expectRevert(abi.encodeWithSelector(UniswapV2Adapter.OnlyVaultCanCallThisFunction.selector));
        adapter.invest(IERC20(address(tokenA)), 100 * 10 ** 18);
    }

    function testDivest() public {
        // First invest
        vm.prank(vault);
        tokenA.approve(address(adapter), 100 * 10 ** 18);

        vm.prank(vault);
        adapter.invest(IERC20(address(tokenA)), 100 * 10 ** 18);

        // Test that vault can divest
        vm.prank(vault);
        uint256 divestedAmount = adapter.divest(IERC20(address(tokenA)), 50 * 10 ** 18);

        // Check that tokens were transferred back to vault
        assertGt(divestedAmount, 0);
        assertGt(tokenA.balanceOf(vault), 900 * 10 ** 18); // Should have more than initial 900 tokens
    }

    function testDivestFromNonVault() public {
        // Test that non-vault cannot divest
        vm.prank(address(0x456));
        vm.expectRevert(abi.encodeWithSelector(UniswapV2Adapter.OnlyVaultCanCallThisFunction.selector));
        adapter.divest(IERC20(address(tokenA)), 100 * 10 ** 18);
    }

    function testGetTotalValue() public {
        // Initially should be 0
        assertEq(adapter.getTotalValue(IERC20(address(tokenA))), 0);

        // After investing
        vm.prank(vault);
        tokenA.approve(address(adapter), 100 * 10 ** 18);

        vm.prank(vault);
        adapter.invest(IERC20(address(tokenA)), 100 * 10 ** 18);

        // Should have some value
        uint256 totalValue = adapter.getTotalValue(IERC20(address(tokenA)));
        assertGt(totalValue, 0);
    }

    function testGetName() public view {
        assertEq(adapter.getName(), "UniswapV2");
    }
}
