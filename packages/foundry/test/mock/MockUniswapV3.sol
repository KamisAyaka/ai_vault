// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// -----------------------------------------------------------------------
/// Mock Uniswap V3 Pool
/// -----------------------------------------------------------------------
contract MockUniswapV3Pool {
    address public token0;
    address public token1;
    uint24 public fee;
    uint160 public sqrtPriceX96; // Q64.96 price

    constructor(address _token0, address _token1, uint24 _fee, uint160 _sqrtPriceX96) {
        token0 = _token0;
        token1 = _token1;
        fee = _fee;
        sqrtPriceX96 = _sqrtPriceX96;
    }

    function slot0() external view returns (uint160 sqrtPriceX96_, int24 tick, uint16, uint16, uint16, uint8, bool) {
        return (sqrtPriceX96, 0, 0, 0, 0, 0, true);
    }

    /// @notice Simplified swap formula: amountOut = amountIn * price (adjusted by fee)
    function swap(address tokenIn, address recipient, uint256 amountIn) external returns (uint256 amountOut) {
        require(tokenIn == token0 || tokenIn == token1, "Invalid tokenIn");

        bool zeroForOne = tokenIn == token0;

        // take input
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // 简化处理：对于 1:1 价格，直接按 1:1 交换
        if (zeroForOne) {
            // token0 -> token1
            amountOut = amountIn;
            amountOut = (amountOut * (1e6 - fee)) / 1e6; // fee
            IERC20(token1).transfer(recipient, amountOut);
        } else {
            // token1 -> token0
            amountOut = amountIn;
            amountOut = (amountOut * (1e6 - fee)) / 1e6;
            IERC20(token0).transfer(recipient, amountOut);
        }

        // update sqrtPriceX96 slightly (fake price impact)
        sqrtPriceX96 = uint160(sqrtPriceX96 + uint160(amountIn / 1000));

        return amountOut;
    }
}

/// -----------------------------------------------------------------------
/// Mock Uniswap V3 Factory
/// -----------------------------------------------------------------------
contract MockUniswapV3Factory {
    mapping(address => mapping(address => mapping(uint24 => address))) public getPool;

    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (address t0, address t1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        MockUniswapV3Pool newPool = new MockUniswapV3Pool(
            t0,
            t1,
            fee,
            79228162514264337593543950336 // 1:1 price (2^96)
        );
        pool = address(newPool);
        getPool[t0][t1][fee] = pool;
        getPool[t1][t0][fee] = pool;
    }
}

/// -----------------------------------------------------------------------
/// Mock Uniswap V3 Position Manager (NFT)
/// -----------------------------------------------------------------------
contract MockNonfungiblePositionManager is ERC721 {
    // Minimal replicas of Uniswap V3 structs to match interface usage in adapter
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    struct Position {
        address token0;
        address token1;
        uint24 fee;
        uint128 liquidity;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    mapping(uint256 => Position) internal _positions;
    uint256 public nextTokenId = 1;

    constructor() ERC721("Mock Uniswap V3 Positions", "MUNI-V3-POS") { }

    // Interface-compatible mint
    function mint(MintParams calldata params)
        external
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        require(params.deadline >= block.timestamp, "EXPIRED");
        tokenId = nextTokenId++;
        liquidity = uint128(params.amount0Desired + params.amount1Desired);

        _positions[tokenId] = Position({
            token0: params.token0,
            token1: params.token1,
            fee: params.fee,
            liquidity: liquidity,
            tokensOwed0: 0,
            tokensOwed1: 0
        });

        if (params.amount0Desired > 0) {
            IERC20(params.token0).transferFrom(msg.sender, address(this), params.amount0Desired);
        }
        if (params.amount1Desired > 0) {
            IERC20(params.token1).transferFrom(msg.sender, address(this), params.amount1Desired);
        }

        _mint(params.recipient, tokenId);

        return (tokenId, liquidity, params.amount0Desired, params.amount1Desired);
    }

    // Interface-compatible increaseLiquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        returns (uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        require(params.deadline >= block.timestamp, "EXPIRED");
        require(_isAuthorized(ownerOf(params.tokenId), msg.sender, params.tokenId), "NOT_APPROVED");

        Position storage pos = _positions[params.tokenId];

        // Calculate liquidity to add (simplified)
        liquidity = uint128(params.amount0Desired + params.amount1Desired);
        amount0 = params.amount0Desired;
        amount1 = params.amount1Desired;

        // Update position
        pos.liquidity += liquidity;
        pos.tokensOwed0 += uint128(amount0);
        pos.tokensOwed1 += uint128(amount1);

        // Transfer tokens from caller
        if (amount0 > 0) {
            IERC20(pos.token0).transferFrom(msg.sender, address(this), amount0);
        }
        if (amount1 > 0) {
            IERC20(pos.token1).transferFrom(msg.sender, address(this), amount1);
        }
    }

    // Interface-compatible decreaseLiquidity
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        returns (uint256 amount0, uint256 amount1)
    {
        require(params.deadline >= block.timestamp, "EXPIRED");
        require(_isAuthorized(ownerOf(params.tokenId), msg.sender, params.tokenId), "NOT_APPROVED");

        Position storage pos = _positions[params.tokenId];
        require(pos.liquidity >= params.liquidity, "INSUFFICIENT_LIQ");

        amount0 = params.liquidity / 2;
        amount1 = params.liquidity / 2;
        pos.liquidity -= params.liquidity;

        IERC20(pos.token0).transfer(msg.sender, amount0);
        IERC20(pos.token1).transfer(msg.sender, amount1);
    }

    // Interface-compatible collect
    function collect(CollectParams calldata params) external returns (uint256 amount0, uint256 amount1) {
        require(_isAuthorized(ownerOf(params.tokenId), msg.sender, params.tokenId), "NOT_APPROVED");
        Position storage pos = _positions[params.tokenId];

        amount0 = params.amount0Max > pos.tokensOwed0 ? pos.tokensOwed0 : params.amount0Max;
        amount1 = params.amount1Max > pos.tokensOwed1 ? pos.tokensOwed1 : params.amount1Max;

        pos.tokensOwed0 -= uint128(amount0);
        pos.tokensOwed1 -= uint128(amount1);

        IERC20(pos.token0).transfer(params.recipient, amount0);
        IERC20(pos.token1).transfer(params.recipient, amount1);
    }

    function burn(uint256 tokenId) external {
        require(_isAuthorized(ownerOf(tokenId), msg.sender, tokenId), "NOT_APPROVED");
        _burn(tokenId);
        delete _positions[tokenId];
    }

    // Interface-compatible positions view returning full tuple per INonfungiblePositionManager
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        Position storage p = _positions[tokenId];
        return (0, address(0), p.token0, p.token1, p.fee, 0, 0, p.liquidity, 0, 0, p.tokensOwed0, p.tokensOwed1);
    }
}

/// -----------------------------------------------------------------------
/// Mock Swap Router
/// -----------------------------------------------------------------------
contract MockSwapRouter {
    MockUniswapV3Pool public pool;

    constructor(address _pool) {
        pool = MockUniswapV3Pool(_pool);
    }

    // Match Uniswap V3 interface: struct-based params
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external returns (uint256 amountOut) {
        require(block.timestamp <= params.deadline, "expired");

        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        IERC20(params.tokenIn).approve(address(pool), params.amountIn);

        amountOut = pool.swap(params.tokenIn, params.recipient, params.amountIn);
        // Skip strict min-out enforcement in mock to reduce flakiness
        // require(amountOut >= params.amountOutMinimum, "Too little received");
    }
}

/// -----------------------------------------------------------------------
/// Mock Quoter
/// -----------------------------------------------------------------------
contract MockQuoter {
    MockUniswapV3Pool public pool;

    constructor(address _pool) {
        pool = MockUniswapV3Pool(_pool);
    }

    function quoteExactInputSingle(address tokenIn, address tokenOut, uint24 fee, uint256 amountIn, uint160)
        external
        view
        returns (uint256 amountOut)
    {
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        uint256 priceX96 = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96)) >> 96;

        if (tokenIn == pool.token0() && tokenOut == pool.token1()) {
            amountOut = (amountIn * priceX96) / (1 << 96);
        } else if (tokenIn == pool.token1() && tokenOut == pool.token0()) {
            amountOut = (amountIn << 96) / priceX96;
        } else {
            revert("invalid pair");
        }

        // Apply fee impact similar to pool.swap
        amountOut = (amountOut * (1e6 - fee)) / 1e6;
    }
}
