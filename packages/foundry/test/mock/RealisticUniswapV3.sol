// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// 导入Uniswap V3的核心库
import "../../contracts/vendor/UniswapV3/core/libraries/TickMath.sol";
import "../../contracts/vendor/UniswapV3/core/libraries/FixedPoint96.sol";
import "../../contracts/vendor/UniswapV3/core/libraries/FullMath.sol";
import "../../contracts/vendor/UniswapV3/periphery/LiquidityAmounts.sol";

/// -----------------------------------------------------------------------
/// 更真实的Uniswap V3 Pool Mock
/// -----------------------------------------------------------------------
contract RealisticUniswapV3Pool {
    address public token0;
    address public token1;
    uint24 public fee;
    uint160 public sqrtPriceX96; // Q64.96 price
    int24 public tick;
    uint128 public liquidity; // 当前池子的总流动性

    constructor(address _token0, address _token1, uint24 _fee, uint160 _sqrtPriceX96) {
        token0 = _token0;
        token1 = _token1;
        fee = _fee;
        sqrtPriceX96 = _sqrtPriceX96;
        // 简化的 tick 计算，避免使用 getTickAtSqrtRatio
        tick = int24(int256(uint256(_sqrtPriceX96)) / 1e12);
        liquidity = 0;
    }

    function slot0() external view returns (uint160 sqrtPriceX96_, int24 tick_, uint16, uint16, uint16, uint8, bool) {
        return (sqrtPriceX96, tick, 0, 0, 0, 0, true);
    }

    /// @notice 更真实的swap实现
    function swap(address tokenIn, address recipient, uint256 amountIn) external returns (uint256 amountOut) {
        require(tokenIn == token0 || tokenIn == token1, "Invalid tokenIn");

        bool zeroForOne = tokenIn == token0;

        // 取输入代币
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        if (zeroForOne) {
            // token0 -> token1
            // 使用更真实的价格计算
            amountOut = _calculateAmountOut(amountIn, true);
            IERC20(token1).transfer(recipient, amountOut);
        } else {
            // token1 -> token0
            amountOut = _calculateAmountOut(amountIn, false);
            IERC20(token0).transfer(recipient, amountOut);
        }

        // 更新价格（模拟真实的价格影响）
        _updatePrice(amountIn, zeroForOne);

        return amountOut;
    }

    function _calculateAmountOut(uint256 amountIn, bool zeroForOne) internal view returns (uint256 amountOut) {
        if (zeroForOne) {
            // token0 -> token1: amountOut = amountIn * price
            amountOut = FullMath.mulDiv(amountIn, sqrtPriceX96, FixedPoint96.Q96);
            amountOut = FullMath.mulDiv(amountOut, sqrtPriceX96, FixedPoint96.Q96);
        } else {
            // token1 -> token0: amountOut = amountIn / price
            amountOut = FullMath.mulDiv(amountIn, FixedPoint96.Q96, sqrtPriceX96);
            amountOut = FullMath.mulDiv(amountOut, FixedPoint96.Q96, sqrtPriceX96);
        }

        // 应用手续费
        amountOut = (amountOut * (1e6 - fee)) / 1e6;
    }

    function _updatePrice(uint256 amountIn, bool zeroForOne) internal {
        // 简化的价格更新逻辑
        uint256 priceImpact = amountIn / 1000000; // 很小的价格影响
        if (zeroForOne) {
            sqrtPriceX96 = uint160(uint256(sqrtPriceX96) + priceImpact);
        } else {
            sqrtPriceX96 = uint160(uint256(sqrtPriceX96) - priceImpact);
        }
        // 简化的 tick 计算，避免使用 getTickAtSqrtRatio
        tick = int24(int256(uint256(sqrtPriceX96)) / 1e12);
    }
}

/// -----------------------------------------------------------------------
/// 更真实的Uniswap V3 Factory Mock
/// -----------------------------------------------------------------------
contract RealisticUniswapV3Factory {
    mapping(address => mapping(address => mapping(uint24 => address))) public getPool;

    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (address t0, address t1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        RealisticUniswapV3Pool newPool = new RealisticUniswapV3Pool(
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
/// 更真实的Uniswap V3 Position Manager Mock
/// -----------------------------------------------------------------------
contract RealisticNonfungiblePositionManager is ERC721 {
    using Math for uint256;

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
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    mapping(uint256 => Position) internal _positions;
    uint256 public nextTokenId = 1;

    constructor() ERC721("Realistic Uniswap V3 Positions", "RUNI-V3-POS") { }

    function mint(MintParams calldata params)
        external
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        require(params.deadline >= block.timestamp, "EXPIRED");
        tokenId = nextTokenId++;

        // 获取当前池子价格
        RealisticUniswapV3Pool pool = RealisticUniswapV3Pool(_getPoolAddress(params.token0, params.token1, params.fee));
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();

        // 使用真实的Uniswap V3算法计算流动性
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(params.tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(params.tickUpper);

        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96, params.amount0Desired, params.amount1Desired
        );

        // 如果计算出的流动性为0，但至少有一种代币，则使用简化的计算
        if (liquidity == 0 && (params.amount0Desired > 0 || params.amount1Desired > 0)) {
            liquidity = uint128(params.amount0Desired + params.amount1Desired);
        }

        // 计算实际需要的代币数量
        (amount0, amount1) =
            LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96, liquidity);

        _positions[tokenId] = Position({
            token0: params.token0,
            token1: params.token1,
            fee: params.fee,
            tickLower: params.tickLower,
            tickUpper: params.tickUpper,
            liquidity: liquidity,
            tokensOwed0: 0,
            tokensOwed1: 0
        });

        // 转移代币
        if (amount0 > 0) {
            IERC20(params.token0).transferFrom(msg.sender, address(this), amount0);
        }
        if (amount1 > 0) {
            IERC20(params.token1).transferFrom(msg.sender, address(this), amount1);
        }

        _mint(params.recipient, tokenId);

        return (tokenId, liquidity, amount0, amount1);
    }

    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        returns (uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        require(params.deadline >= block.timestamp, "EXPIRED");
        require(_isAuthorized(ownerOf(params.tokenId), msg.sender, params.tokenId), "NOT_APPROVED");

        Position storage pos = _positions[params.tokenId];

        // 获取当前池子价格
        RealisticUniswapV3Pool pool = RealisticUniswapV3Pool(_getPoolAddress(pos.token0, pos.token1, pos.fee));
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();

        // 使用真实的Uniswap V3算法计算流动性
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(pos.tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(pos.tickUpper);

        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96, params.amount0Desired, params.amount1Desired
        );

        // 如果计算出的流动性为0，但至少有一种代币，则使用简化的计算
        if (liquidity == 0 && (params.amount0Desired > 0 || params.amount1Desired > 0)) {
            liquidity = uint128(params.amount0Desired + params.amount1Desired);
        }

        // 计算实际需要的代币数量
        (amount0, amount1) =
            LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96, liquidity);

        // 更新position
        pos.liquidity += liquidity;
        pos.tokensOwed0 += uint128(amount0);
        pos.tokensOwed1 += uint128(amount1);

        // 转移代币
        if (amount0 > 0) {
            IERC20(pos.token0).transferFrom(msg.sender, address(this), amount0);
        }
        if (amount1 > 0) {
            IERC20(pos.token1).transferFrom(msg.sender, address(this), amount1);
        }
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        returns (uint256 amount0, uint256 amount1)
    {
        require(params.deadline >= block.timestamp, "EXPIRED");
        require(_isAuthorized(ownerOf(params.tokenId), msg.sender, params.tokenId), "NOT_APPROVED");

        Position storage pos = _positions[params.tokenId];
        require(pos.liquidity >= params.liquidity, "INSUFFICIENT_LIQ");

        // 简化计算：直接使用流动性数量作为代币数量
        amount0 = params.liquidity / 2;
        amount1 = params.liquidity / 2;

        // 更新position
        pos.liquidity -= params.liquidity;
        pos.tokensOwed0 += uint128(amount0);
        pos.tokensOwed1 += uint128(amount1);

        // 转移代币（检查余额）
        if (amount0 > 0) {
            uint256 balance0 = IERC20(pos.token0).balanceOf(address(this));
            uint256 transfer0 = amount0 > balance0 ? balance0 : amount0;
            if (transfer0 > 0) {
                IERC20(pos.token0).transfer(msg.sender, transfer0);
            }
        }
        if (amount1 > 0) {
            uint256 balance1 = IERC20(pos.token1).balanceOf(address(this));
            uint256 transfer1 = amount1 > balance1 ? balance1 : amount1;
            if (transfer1 > 0) {
                IERC20(pos.token1).transfer(msg.sender, transfer1);
            }
        }
    }

    function collect(CollectParams calldata params) external returns (uint256 amount0, uint256 amount1) {
        require(_isAuthorized(ownerOf(params.tokenId), msg.sender, params.tokenId), "NOT_APPROVED");
        Position storage pos = _positions[params.tokenId];

        amount0 = params.amount0Max > pos.tokensOwed0 ? pos.tokensOwed0 : params.amount0Max;
        amount1 = params.amount1Max > pos.tokensOwed1 ? pos.tokensOwed1 : params.amount1Max;

        pos.tokensOwed0 -= uint128(amount0);
        pos.tokensOwed1 -= uint128(amount1);

        if (amount0 > 0) {
            uint256 balance0 = IERC20(pos.token0).balanceOf(address(this));
            uint256 transfer0 = amount0 > balance0 ? balance0 : amount0;
            if (transfer0 > 0) {
                IERC20(pos.token0).transfer(params.recipient, transfer0);
            }
        }
        if (amount1 > 0) {
            uint256 balance1 = IERC20(pos.token1).balanceOf(address(this));
            uint256 transfer1 = amount1 > balance1 ? balance1 : amount1;
            if (transfer1 > 0) {
                IERC20(pos.token1).transfer(params.recipient, transfer1);
            }
        }
    }

    function burn(uint256 tokenId) external {
        require(_isAuthorized(ownerOf(tokenId), msg.sender, tokenId), "NOT_APPROVED");
        _burn(tokenId);
        delete _positions[tokenId];
    }

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
        return (
            0,
            address(0),
            p.token0,
            p.token1,
            p.fee,
            p.tickLower,
            p.tickUpper,
            p.liquidity,
            0,
            0,
            p.tokensOwed0,
            p.tokensOwed1
        );
    }

    address public factory;

    function setFactory(address _factory) external {
        factory = _factory;
    }

    function _getPoolAddress(address token0, address token1, uint24 fee) internal view returns (address) {
        require(factory != address(0), "Factory not set");
        return RealisticUniswapV3Factory(factory).getPool(token0, token1, fee);
    }

    // 添加用于测试的方法
    function setLiquidity(uint256 tokenId, uint128 newLiquidity) external {
        _positions[tokenId].liquidity = newLiquidity;
    }
}

/// -----------------------------------------------------------------------
/// 更真实的Swap Router Mock
/// -----------------------------------------------------------------------
contract RealisticSwapRouter {
    RealisticUniswapV3Pool public pool;

    constructor(address _pool) {
        pool = RealisticUniswapV3Pool(_pool);
    }

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
        require(amountOut >= params.amountOutMinimum, "Too little received");
    }
}

/// -----------------------------------------------------------------------
/// 更真实的Quoter Mock
/// -----------------------------------------------------------------------
contract RealisticQuoter {
    RealisticUniswapV3Pool public pool;

    constructor(address _pool) {
        pool = RealisticUniswapV3Pool(_pool);
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

        // 应用手续费
        amountOut = (amountOut * (1e6 - fee)) / 1e6;
    }
}
