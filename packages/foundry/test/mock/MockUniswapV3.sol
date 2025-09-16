// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Mock Uniswap V3 Pool contract for testing
contract MockUniswapV3Pool {
    address public token0;
    address public token1;
    uint24 public fee;
    uint160 public sqrtPriceX96;
    
    constructor(address _token0, address _token1, uint24 _fee) {
        token0 = _token0;
        token1 = _token1;
        fee = _fee;
        sqrtPriceX96 = 79228162514264337593543950336; // Default price (1:1)
    }
    
    function slot0() external view returns (
        uint160 sqrtPriceX96_,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    ) {
        return (sqrtPriceX96, 0, 0, 0, 0, 0, true);
    }
    
    function setSqrtPriceX96(uint160 _sqrtPriceX96) external {
        sqrtPriceX96 = _sqrtPriceX96;
    }
}

// Mock Uniswap V3 Factory contract for testing
contract MockUniswapV3Factory {
    mapping(address => mapping(address => mapping(uint24 => address))) public getPool;
    
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool) {
        require(tokenA != tokenB, "UniswapV3Factory: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV3Factory: ZERO_ADDRESS");
        
        MockUniswapV3Pool newPool = new MockUniswapV3Pool(token0, token1, fee);
        pool = address(newPool);
        getPool[token0][token1][fee] = pool;
        getPool[token1][token0][fee] = pool;
        return pool;
    }
    
    function getPoolAddress(address tokenA, address tokenB, uint24 fee) external view returns (address) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return getPool[token0][token1][fee];
    }
}

// Mock Uniswap V3 Position NFT contract for testing
contract MockNonfungiblePositionManager is ERC721 {
    struct Position {
        uint96 nonce;
        address operator;
        address token0;
        address token1;
        address pool;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }
    
    mapping(uint256 => Position) public positions;
    mapping(uint256 => bool) public exists;
    uint256 public nextTokenId = 1;
    
    constructor() ERC721("Uniswap V3 Positions", "UNI-V3-POS") {}
    
    function mint(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address recipient,
        uint256 deadline
    ) external returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    ) {
        require(deadline >= block.timestamp, "UniswapV3: EXPIRED");
        require(amount0Desired >= amount0Min, "UniswapV3: INSUFFICIENT_AMOUNT0");
        require(amount1Desired >= amount1Min, "UniswapV3: INSUFFICIENT_AMOUNT1");
        
        tokenId = nextTokenId++;
        liquidity = uint128(amount0Desired + amount1Desired); // Simplified for testing
        
        positions[tokenId] = Position({
            nonce: 0,
            operator: address(0),
            token0: token0,
            token1: token1,
            pool: address(0), // Will be set later
            fee: fee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity,
            feeGrowthInside0LastX128: 0,
            feeGrowthInside1LastX128: 0,
            tokensOwed0: 0,
            tokensOwed1: 0
        });
        
        exists[tokenId] = true;
        
        // Transfer tokens from sender
        if (amount0Desired > 0) {
            IERC20(token0).transferFrom(msg.sender, address(this), amount0Desired);
        }
        if (amount1Desired > 0) {
            IERC20(token1).transferFrom(msg.sender, address(this), amount1Desired);
        }
        
        _mint(recipient, tokenId);
        
        amount0 = amount0Desired;
        amount1 = amount1Desired;
        
        return (tokenId, liquidity, amount0, amount1);
    }
    
    function decreaseLiquidity(
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline
    ) external returns (uint256 amount0, uint256 amount1) {
        require(deadline >= block.timestamp, "UniswapV3: EXPIRED");
        require(_isApprovedOrOwner(msg.sender, tokenId), "UniswapV3: NOT_APPROVED");
        
        Position storage position = positions[tokenId];
        require(position.liquidity >= liquidity, "UniswapV3: INSUFFICIENT_LIQUIDITY");
        
        amount0 = liquidity / 2;
        amount1 = liquidity / 2;
        
        require(amount0 >= amount0Min, "UniswapV3: INSUFFICIENT_AMOUNT0");
        require(amount1 >= amount1Min, "UniswapV3: INSUFFICIENT_AMOUNT1");
        
        position.liquidity -= liquidity;
        position.tokensOwed0 += uint128(amount0);
        position.tokensOwed1 += uint128(amount1);
        
        // Transfer tokens to sender
        IERC20(position.token0).transfer(msg.sender, amount0);
        IERC20(position.token1).transfer(msg.sender, amount1);
        
        return (amount0, amount1);
    }
    
    function collect(
        uint256 tokenId,
        address recipient,
        uint128 amount0Max,
        uint128 amount1Max
    ) external returns (uint256 amount0, uint256 amount1) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "UniswapV3: NOT_APPROVED");
        
        Position storage position = positions[tokenId];
        
        amount0 = amount0Max > position.tokensOwed0 ? position.tokensOwed0 : amount0Max;
        amount1 = amount1Max > position.tokensOwed1 ? position.tokensOwed1 : amount1Max;
        
        position.tokensOwed0 -= uint128(amount0);
        position.tokensOwed1 -= uint128(amount1);
        
        // Transfer tokens to recipient
        IERC20(position.token0).transfer(recipient, amount0);
        IERC20(position.token1).transfer(recipient, amount1);
        
        return (amount0, amount1);
    }
    
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "UniswapV3: NOT_APPROVED");
        _burn(tokenId);
        delete positions[tokenId];
        exists[tokenId] = false;
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(exists[tokenId], "UniswapV3: INVALID_TOKEN_ID");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
}

// Mock Uniswap V3 Swap Router contract for testing
contract MockSwapRouter {
    function exactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        address recipient,
        uint256 deadline,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut) {
        require(deadline >= block.timestamp, "UniswapV3: EXPIRED");
        
        // Transfer input tokens from sender
        bool success = IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        require(success, "UniswapV3: TRANSFER_FAILED");
        
        // Calculate output (simplified 1:1 ratio)
        amountOut = amountIn;
        require(amountOut >= amountOutMinimum, "UniswapV3: INSUFFICIENT_OUTPUT_AMOUNT");
        
        // Transfer output tokens to recipient
        success = IERC20(tokenOut).transfer(recipient, amountOut);
        require(success, "UniswapV3: TRANSFER_FAILED");
        
        return amountOut;
    }
}

// Mock Uniswap V3 Quoter contract for testing
contract MockQuoter {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut) {
        // Simplified 1:1 ratio
        return amountIn;
    }
}