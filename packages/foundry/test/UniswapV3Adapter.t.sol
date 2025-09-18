// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol";
import "./mock/MockToken.sol";
import "./mock/RealisticUniswapV3.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UniswapV3AdapterTest is Test {
    UniswapV3Adapter public adapter;
    RealisticSwapRouter public mockRouter;
    RealisticNonfungiblePositionManager public mockPositionManager;
    RealisticUniswapV3Factory public mockFactory;
    RealisticQuoter public mockQuoter;
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
        tokenA.mint(vault, 2000 * 10 ** 18);
        tokenB.mint(vault, 2000 * 10 ** 18);

        // Deploy mock Uniswap V3 contracts
        mockPositionManager = new RealisticNonfungiblePositionManager();
        mockFactory = new RealisticUniswapV3Factory();

        // Create pool with correct token order
        address poolAddress = mockFactory.createPool(
            address(tokenA),
            address(tokenB),
            3000
        ); // 0.3% fee tier

        // 给池子一些初始代币用于交换
        vm.prank(vault);
        tokenA.transfer(poolAddress, 1000 * 10 ** 18);
        vm.prank(vault);
        tokenB.transfer(poolAddress, 1000 * 10 ** 18);

        mockRouter = new RealisticSwapRouter(poolAddress);
        mockQuoter = new RealisticQuoter(poolAddress);

        // 设置factory地址
        mockPositionManager.setFactory(address(mockFactory));

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

        //Seed pool with token balances so mock swap has liquidity to pay out
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

    function testMultipleInvestmentsUseSameNFT() public {
        // 第一次投资
        vm.prank(vault);
        tokenA.approve(address(adapter), 100 * 10 ** 18);
        vm.prank(vault);
        adapter.invest(IERC20(address(tokenA)), 100 * 10 ** 18);

        // 获取第一次投资后的tokenId
        UniswapV3Adapter.TokenConfig memory config1 = adapter.getTokenConfig(
            IERC20(address(tokenA))
        );
        uint256 firstTokenId = config1.tokenId;
        assertGt(firstTokenId, 0, "First investment should create NFT");

        // 第二次投资
        vm.prank(vault);
        tokenA.approve(address(adapter), 50 * 10 ** 18);
        vm.prank(vault);
        adapter.invest(IERC20(address(tokenA)), 50 * 10 ** 18);

        // 验证使用的是同一个NFT
        UniswapV3Adapter.TokenConfig memory config2 = adapter.getTokenConfig(
            IERC20(address(tokenA))
        );
        uint256 secondTokenId = config2.tokenId;
        assertEq(
            secondTokenId,
            firstTokenId,
            "Second investment should use same NFT"
        );
    }

    function testPartialDivestmentKeepsNFT() public {
        // 先投资
        vm.prank(vault);
        tokenA.approve(address(adapter), 100 * 10 ** 18);
        vm.prank(vault);
        adapter.invest(IERC20(address(tokenA)), 100 * 10 ** 18);

        // 获取投资后的tokenId
        UniswapV3Adapter.TokenConfig memory configBefore = adapter
            .getTokenConfig(IERC20(address(tokenA)));
        uint256 tokenIdBefore = configBefore.tokenId;
        assertGt(tokenIdBefore, 0, "Investment should create NFT");

        // 给池子和position manager一些代币用于撤资
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
        vm.prank(vault);
        tokenA.transfer(address(mockPositionManager), 100 * 10 ** 18);
        vm.prank(vault);
        tokenB.transfer(address(mockPositionManager), 100 * 10 ** 18);

        // 部分撤资
        vm.prank(vault);
        adapter.divest(IERC20(address(tokenA)), 30 * 10 ** 18);

        // 验证NFT仍然存在
        UniswapV3Adapter.TokenConfig memory configAfter = adapter
            .getTokenConfig(IERC20(address(tokenA)));
        uint256 tokenIdAfter = configAfter.tokenId;
        assertEq(
            tokenIdAfter,
            tokenIdBefore,
            "Partial divestment should keep NFT"
        );
    }

    function testFullDivestmentBurnsNFT() public {
        // 先投资
        vm.prank(vault);
        tokenA.approve(address(adapter), 100 * 10 ** 18);
        vm.prank(vault);
        adapter.invest(IERC20(address(tokenA)), 100 * 10 ** 18);

        // 获取投资后的tokenId
        UniswapV3Adapter.TokenConfig memory configBefore = adapter
            .getTokenConfig(IERC20(address(tokenA)));
        uint256 tokenIdBefore = configBefore.tokenId;
        assertGt(tokenIdBefore, 0, "Investment should create NFT");

        // 给池子和position manager一些代币用于撤资
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
        vm.prank(vault);
        tokenA.transfer(address(mockPositionManager), 100 * 10 ** 18);
        vm.prank(vault);
        tokenB.transfer(address(mockPositionManager), 100 * 10 ** 18);

        // 完全撤资
        vm.prank(vault);
        adapter.divest(IERC20(address(tokenA)), 100 * 10 ** 18);

        // 验证NFT被销毁
        UniswapV3Adapter.TokenConfig memory configAfter = adapter
            .getTokenConfig(IERC20(address(tokenA)));
        uint256 tokenIdAfter = configAfter.tokenId;
        assertEq(tokenIdAfter, 0, "Full divestment should burn NFT");
    }

    function testConfigUpdateCreatesNewNFT() public {
        // 先投资
        vm.prank(vault);
        tokenA.approve(address(adapter), 100 * 10 ** 18);
        vm.prank(vault);
        adapter.invest(IERC20(address(tokenA)), 100 * 10 ** 18);

        // 获取投资后的tokenId
        UniswapV3Adapter.TokenConfig memory configBefore = adapter
            .getTokenConfig(IERC20(address(tokenA)));
        uint256 tokenIdBefore = configBefore.tokenId;
        assertGt(tokenIdBefore, 0, "Investment should create NFT");

        // 给池子和position manager一些代币用于撤资
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
        vm.prank(vault);
        tokenA.transfer(address(mockPositionManager), 100 * 10 ** 18);
        vm.prank(vault);
        tokenB.transfer(address(mockPositionManager), 100 * 10 ** 18);

        // 更新配置（改变价格区间）
        vm.prank(owner);
        adapter.UpdateTokenConfig(
            IERC20(address(tokenA)),
            IERC20(address(tokenB)),
            3000, // 相同的费率
            -1200, // 新的价格区间下限
            1200 // 新的价格区间上限
        );

        // 验证创建了新的NFT
        UniswapV3Adapter.TokenConfig memory configAfter = adapter
            .getTokenConfig(IERC20(address(tokenA)));
        uint256 tokenIdAfter = configAfter.tokenId;
        assertGt(tokenIdAfter, 0, "Config update should create new NFT");
        assertTrue(
            tokenIdAfter != tokenIdBefore,
            "New NFT should be different from old one"
        );
    }

    function testConfigUpdateAlwaysCreatesNewNFT() public {
        // 先投资
        vm.prank(vault);
        tokenA.approve(address(adapter), 100 * 10 ** 18);
        vm.prank(vault);
        adapter.invest(IERC20(address(tokenA)), 100 * 10 ** 18);

        // 获取投资后的tokenId
        UniswapV3Adapter.TokenConfig memory configBefore = adapter
            .getTokenConfig(IERC20(address(tokenA)));
        uint256 tokenIdBefore = configBefore.tokenId;
        assertGt(tokenIdBefore, 0, "Investment should create NFT");

        // 给池子和position manager一些代币用于撤资和重新投资
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
        vm.prank(vault);
        tokenA.transfer(address(mockPositionManager), 100 * 10 ** 18);
        vm.prank(vault);
        tokenB.transfer(address(mockPositionManager), 100 * 10 ** 18);

        // 更新配置（即使相同的配置也会重新铸造NFT）
        vm.prank(owner);
        adapter.UpdateTokenConfig(
            IERC20(address(tokenA)),
            IERC20(address(tokenB)),
            3000, // 相同的费率
            -600, // 相同的价格区间下限
            600 // 相同的价格区间上限
        );

        // 验证创建了新的NFT
        UniswapV3Adapter.TokenConfig memory configAfter = adapter
            .getTokenConfig(IERC20(address(tokenA)));
        uint256 tokenIdAfter = configAfter.tokenId;
        assertGt(tokenIdAfter, 0, "Config update should always create new NFT");
        assertTrue(
            tokenIdAfter != tokenIdBefore,
            "New NFT should be different from old one"
        );
    }
}
