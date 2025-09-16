**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [incorrect-exp](#incorrect-exp) (2 results) (High)
 - [divide-before-multiply](#divide-before-multiply) (41 results) (Medium)
 - [incorrect-equality](#incorrect-equality) (1 results) (Medium)
 - [reentrancy-no-eth](#reentrancy-no-eth) (6 results) (Medium)
 - [unused-return](#unused-return) (14 results) (Medium)
 - [calls-loop](#calls-loop) (20 results) (Low)
 - [reentrancy-benign](#reentrancy-benign) (1 results) (Low)
 - [reentrancy-events](#reentrancy-events) (14 results) (Low)
 - [timestamp](#timestamp) (1 results) (Low)
 - [assembly](#assembly) (21 results) (Informational)
 - [pragma](#pragma) (1 results) (Informational)
 - [cyclomatic-complexity](#cyclomatic-complexity) (1 results) (Informational)
 - [solc-version](#solc-version) (8 results) (Informational)
 - [low-level-calls](#low-level-calls) (3 results) (Informational)
 - [naming-convention](#naming-convention) (19 results) (Informational)
 - [too-many-digits](#too-many-digits) (3 results) (Informational)
## incorrect-exp
Impact: High
Confidence: Medium
 - [ ] ID-0
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) has bitwise-xor operator ^ instead of the exponentiation operator **: 
	 - [inv = (3 * denominator) ^ 2](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L82)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-1
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) has bitwise-xor operator ^ instead of the exponentiation operator **: 
	 - [inverse = (3 * denominator) ^ 2](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L257)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


## divide-before-multiply
Impact: Medium
Confidence: Medium
 - [ ] ID-2
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L47)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-3
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [prod0 = prod0 / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L67)
	- [result = prod0 * inv](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L99)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-4
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L62)
	- [inv *= 2 - denominator * inv](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-5
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L77)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-6
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L32)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-7
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L62)
	- [inv *= 2 - denominator * inv](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L89)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-8
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L265)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-9
[UniswapAdapter._calculateMinAmounts(IERC20,IUniswapV2Pair,uint112,uint112,uint256,uint256,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L372-L403) performs a multiplication on the result of a division:
	- [((((uint256(reserve0) * liquidityAmount) / totalSupply) * (BASIS_POINTS_DIVISOR - slippageTolerance)) / BASIS_POINTS_DIVISOR,(((uint256(reserve1) * liquidityAmount) / totalSupply) * (BASIS_POINTS_DIVISOR - slippageTolerance)) / BASIS_POINTS_DIVISOR)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L385-L392)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L372-L403


 - [ ] ID-10
[UniswapAdapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L185-L238) performs a multiplication on the result of a division:
	- [amountOfTokenToSwap = amount / 2](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L187)
	- [(tokenAmount,counterPartyTokenAmount,liquidity) = i_uniswapRouter.addLiquidity({tokenA:address(asset),tokenB:address(config.counterPartyToken),amountADesired:amountOfTokenToSwap,amountBDesired:actualTokenB,amountAMin:(amountOfTokenToSwap * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,amountBMin:(actualTokenB * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L212-L229)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L185-L238


 - [ ] ID-11
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L65)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-12
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L80)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-13
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L41)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-14
[UniswapAdapter.getTotalValue(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L406-L435) performs a multiplication on the result of a division:
	- [amount0 = (uint256(reserve0) * liquidityTokens) / totalSupply](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L424)
	- [amount1 + (amount0 * reserve1) / reserve0](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L431)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L406-L435


 - [ ] ID-15
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse = (3 * denominator) ^ 2](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L257)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-16
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L62)
	- [inv *= 2 - denominator * inv](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L91)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-17
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L38)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-18
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L35)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-19
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [low = low / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L245)
	- [result = low * inverse](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L272)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-20
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L62)
	- [inv *= 2 - denominator * inv](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L87)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-21
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L62)
	- [inv *= 2 - denominator * inv](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L88)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-22
[Math.invMod(uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L315-L361) performs a multiplication on the result of a division:
	- [quotient = gcd / remainder](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L337)
	- [(gcd,remainder) = (remainder,gcd - remainder * quotient)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L339-L346)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L315-L361


 - [ ] ID-23
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L56)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-24
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L59)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-25
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L62)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-26
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L263)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-27
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L261)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-28
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L29)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-29
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L266)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-30
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L62)
	- [inv *= 2 - denominator * inv](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L90)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-31
[UniswapAdapter._calculateMinAmounts(IERC20,IUniswapV2Pair,uint112,uint112,uint256,uint256,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L372-L403) performs a multiplication on the result of a division:
	- [((((uint256(reserve1) * liquidityAmount) / totalSupply) * (BASIS_POINTS_DIVISOR - slippageTolerance)) / BASIS_POINTS_DIVISOR,(((uint256(reserve0) * liquidityAmount) / totalSupply) * (BASIS_POINTS_DIVISOR - slippageTolerance)) / BASIS_POINTS_DIVISOR)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L395-L402)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L372-L403


 - [ ] ID-32
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L264)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-33
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L74)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-34
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L50)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-35
[UniswapAdapter.getTotalValue(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L406-L435) performs a multiplication on the result of a division:
	- [amount1 = (uint256(reserve1) * liquidityTokens) / totalSupply](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L425)
	- [amount0 + (amount1 * reserve0) / reserve1](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L429)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L406-L435


 - [ ] ID-36
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L62)
	- [inv = (3 * denominator) ^ 2](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L82)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-37
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L83)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-38
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L44)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-39
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L68)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-40
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L262)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-41
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L53)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-42
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L71)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


## incorrect-equality
Impact: Medium
Confidence: High
 - [ ] ID-43
[UniswapAdapter.getTotalValue(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L406-L435) uses a dangerous strict equality:
	- [liquidityTokens == 0](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L417)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L406-L435


## reentrancy-no-eth
Impact: Medium
Confidence: Medium
 - [ ] ID-44
Reentrancy in [UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319):
	External calls:
	- [_removeLiquidityAndCollectTokens(config,config.tokenId,liquidity)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L276-L280)
		- [(amount0,amount1) = i_positionManager.decreaseLiquidity(decreaseParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L784-L786)
		- [i_positionManager.collect(collectParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L797)
	- [i_positionManager.burn(config.tokenId)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L299)
	State variables written after the call(s):
	- [s_tokenConfigs[token].feeTier = newFeeTier](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L301)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241)
	- [UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L146-L161)
	- [UniswapV3Adapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L681-L698)
	- [UniswapV3Adapter._investWithBalances(IERC20,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L570-L673)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L555-L560)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L93-L139)
	- [s_tokenConfigs[token].tickLower = newTickLower](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L302)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241)
	- [UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L146-L161)
	- [UniswapV3Adapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L681-L698)
	- [UniswapV3Adapter._investWithBalances(IERC20,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L570-L673)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L555-L560)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L93-L139)
	- [s_tokenConfigs[token].tickUpper = newTickUpper](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L303)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241)
	- [UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L146-L161)
	- [UniswapV3Adapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L681-L698)
	- [UniswapV3Adapter._investWithBalances(IERC20,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L570-L673)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L555-L560)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L93-L139)
	- [s_tokenConfigs[token].pool = newPool](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L304)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241)
	- [UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L146-L161)
	- [UniswapV3Adapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L681-L698)
	- [UniswapV3Adapter._investWithBalances(IERC20,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L570-L673)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L555-L560)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L93-L139)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319


 - [ ] ID-45
Reentrancy in [VaultShares.updateHoldingAllocation(IProtocolAdapter[],uint256[])](.contracts/protocol/VaultShares.sol#L92-L107):
	External calls:
	- [withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L98)
		- [adapter.divest(IERC20(asset()),valueInAdapter)](.contracts/protocol/VaultShares.sol#L173)
	- [_investInAdapters(vaultAdapters,allocationData)](.contracts/protocol/VaultShares.sol#L101)
		- [vaultAdapters[i].invest(IERC20(asset()),amountToInvest)](.contracts/protocol/VaultShares.sol#L199)
	State variables written after the call(s):
	- [s_allocatedAdapters = vaultAdapters](.contracts/protocol/VaultShares.sol#L104)
	[VaultShares.s_allocatedAdapters](.contracts/protocol/VaultShares.sol#L45) can be used in cross function reentrancies:
	- [VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultShares.sol#L116-L157)
	- [VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L316-L329)
	- [VaultShares.updateHoldingAllocation(IProtocolAdapter[],uint256[])](.contracts/protocol/VaultShares.sol#L92-L107)
	- [VaultShares.withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L162-L176)

.contracts/protocol/VaultShares.sol#L92-L107


 - [ ] ID-46
Reentrancy in [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241):
	External calls:
	- [_divest(token,liquidity,config)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L207)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L379-L385)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L404)
		- [(amount0,amount1) = i_positionManager.decreaseLiquidity(decreaseParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L784-L786)
		- [i_positionManager.collect(collectParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L797)
	- [_invest(token,availableAssets)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L237)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L379-L385)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L404)
		- [(tokenId,liquidityMinted,amount0,amount1) = i_positionManager.mint(mintParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L669-L671)
	State variables written after the call(s):
	- [_invest(token,availableAssets)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L237)
		- [s_tokenConfigs[token].tokenId = tokenId](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L672)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241)
	- [UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L146-L161)
	- [UniswapV3Adapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L681-L698)
	- [UniswapV3Adapter._investWithBalances(IERC20,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L570-L673)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L555-L560)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L93-L139)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241


 - [ ] ID-47
Reentrancy in [UniswapAdapter.updateTokenConfigAndReinvest(IERC20,IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L116-L156):
	External calls:
	- [_divest(token,lpBalance,config)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L144)
		- [amounts = i_uniswapRouter.swapExactTokensForTokens({amountIn:amountIn,amountOutMin:minOut,path:path,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L349-L357)
		- [(tokenAmount,counterPartyAmount) = i_uniswapRouter.removeLiquidity({tokenA:address(asset),tokenB:address(config.counterPartyToken),liquidity:liquidityAmount,amountAMin:minToken,amountBMin:minCounter,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L300-L309)
	State variables written after the call(s):
	- [s_tokenConfigs[token].counterPartyToken = counterPartyToken](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L148)
	[UniswapAdapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L33) can be used in cross function reentrancies:
	- [UniswapAdapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L93-L109)
	- [UniswapAdapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L185-L238)
	- [UniswapAdapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L446-L451)
	- [UniswapAdapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L33)
	- [UniswapAdapter.setTokenConfig(IERC20,uint256,IERC20,address)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L61-L86)
	- [UniswapAdapter.updateTokenConfigAndReinvest(IERC20,IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L116-L156)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L116-L156


 - [ ] ID-48
Reentrancy in [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241):
	External calls:
	- [_divest(token,liquidity,config)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L207)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L379-L385)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L404)
		- [(amount0,amount1) = i_positionManager.decreaseLiquidity(decreaseParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L784-L786)
		- [i_positionManager.collect(collectParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L797)
	State variables written after the call(s):
	- [s_tokenConfigs[token].counterPartyToken = counterPartyToken](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L227)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241)
	- [UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L146-L161)
	- [UniswapV3Adapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L681-L698)
	- [UniswapV3Adapter._investWithBalances(IERC20,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L570-L673)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L555-L560)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L93-L139)
	- [s_tokenConfigs[token].feeTier = feeTier](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L228)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241)
	- [UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L146-L161)
	- [UniswapV3Adapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L681-L698)
	- [UniswapV3Adapter._investWithBalances(IERC20,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L570-L673)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L555-L560)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L93-L139)
	- [s_tokenConfigs[token].tickLower = tickLower](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L229)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241)
	- [UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L146-L161)
	- [UniswapV3Adapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L681-L698)
	- [UniswapV3Adapter._investWithBalances(IERC20,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L570-L673)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L555-L560)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L93-L139)
	- [s_tokenConfigs[token].tickUpper = tickUpper](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L230)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241)
	- [UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L146-L161)
	- [UniswapV3Adapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L681-L698)
	- [UniswapV3Adapter._investWithBalances(IERC20,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L570-L673)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L555-L560)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L93-L139)
	- [s_tokenConfigs[token].pool = pool](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L231)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241)
	- [UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L146-L161)
	- [UniswapV3Adapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L681-L698)
	- [UniswapV3Adapter._investWithBalances(IERC20,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L570-L673)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L555-L560)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L93-L139)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241


 - [ ] ID-49
Reentrancy in [UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319):
	External calls:
	- [_removeLiquidityAndCollectTokens(config,config.tokenId,liquidity)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L276-L280)
		- [(amount0,amount1) = i_positionManager.decreaseLiquidity(decreaseParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L784-L786)
		- [i_positionManager.collect(collectParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L797)
	- [i_positionManager.burn(config.tokenId)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L299)
	- [(liquidityMinted,newAmount0,newAmount1) = _investWithBalances(token,config)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L307-L311)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L379-L385)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L404)
		- [(tokenId,liquidityMinted,amount0,amount1) = i_positionManager.mint(mintParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L669-L671)
	State variables written after the call(s):
	- [(liquidityMinted,newAmount0,newAmount1) = _investWithBalances(token,config)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L307-L311)
		- [s_tokenConfigs[token].tokenId = tokenId](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L672)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241)
	- [UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L146-L161)
	- [UniswapV3Adapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L681-L698)
	- [UniswapV3Adapter._investWithBalances(IERC20,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L570-L673)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L555-L560)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L93-L139)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319


## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-50
[VaultShares.withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L162-L176) ignores return value by [adapter.divest(IERC20(asset()),valueInAdapter)](.contracts/protocol/VaultShares.sol#L173)

.contracts/protocol/VaultShares.sol#L162-L176


 - [ ] ID-51
[UniswapV3Adapter._getPositionAmounts(UniswapV3Adapter.TokenConfig,uint128)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L511-L530) ignores return value by [(sqrtPriceX96,None,None,None,None,None,None) = config.pool.slot0()](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L516)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L511-L530


 - [ ] ID-52
[UniswapV3Adapter._getPositionAmounts(UniswapV3Adapter.TokenConfig,uint128)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L511-L530) ignores return value by [LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96,sqrtRatioAX96,sqrtRatioBX96,liquidity)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L523-L529)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L511-L530


 - [ ] ID-53
[UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241) ignores return value by [(liquidity) = i_positionManager.positions(config.tokenId)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L191-L211)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241


 - [ ] ID-54
[VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultShares.sol#L116-L157) ignores return value by [currentAdapters[divestAdapterIndices[i]].divest(IERC20(asset()),divestAmounts[i])](.contracts/protocol/VaultShares.sol#L138)

.contracts/protocol/VaultShares.sol#L116-L157


 - [ ] ID-55
[UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319) ignores return value by [(liquidity) = i_positionManager.positions(config.tokenId)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L260-L284)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319


 - [ ] ID-56
[VaultShares._investInAdapters(IProtocolAdapter[],uint256[])](.contracts/protocol/VaultShares.sol#L181-L202) ignores return value by [vaultAdapters[i].invest(IERC20(asset()),amountToInvest)](.contracts/protocol/VaultShares.sol#L199)

.contracts/protocol/VaultShares.sol#L181-L202


 - [ ] ID-57
[UniswapV3Adapter.getTotalValue(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L413-L502) ignores return value by [(sqrtPriceX96_scope_0,None,None,None,None,None,None) = config.pool.slot0()](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L477)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L413-L502


 - [ ] ID-58
[UniswapV3Adapter.getTotalValue(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L413-L502) ignores return value by [(token0,token1,liquidity,tokensOwed0,tokensOwed1) = i_positionManager.positions(tokenId)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L425-L501)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L413-L502


 - [ ] ID-59
[UniswapV3Adapter._investWithBalances(IERC20,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L570-L673) ignores return value by [(sqrtPriceX96,None,None,None,None,None,None) = config.pool.slot0()](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L584)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L570-L673


 - [ ] ID-60
[UniswapV3Adapter.getTotalValue(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L413-L502) ignores return value by [(sqrtPriceX96,None,None,None,None,None,None) = config.pool.slot0()](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L452)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L413-L502


 - [ ] ID-61
[UniswapAdapter._divest(IERC20,uint256,UniswapAdapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L270-L332) ignores return value by [(reserve0,reserve1,None) = pair.getReserves()](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L285)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L270-L332


 - [ ] ID-62
[UniswapAdapter.getTotalValue(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L406-L435) ignores return value by [(reserve0,reserve1,None) = pair.getReserves()](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L420)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L406-L435


 - [ ] ID-63
[UniswapV3Adapter._removeLiquidityAndCollectTokens(UniswapV3Adapter.TokenConfig,uint256,uint128)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L754-L798) ignores return value by [i_positionManager.collect(collectParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L797)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L754-L798


## calls-loop
Impact: Low
Confidence: Medium
 - [ ] ID-64
[AIAgentVaultManager.executeBatch(uint256[],uint256[],bytes[])](.contracts/protocol/AIAgentVaultManager.sol#L231-L266) has external calls inside a loop: [(success,result) = target.call{value: values[i]}(data[i])](.contracts/protocol/AIAgentVaultManager.sol#L258)

.contracts/protocol/AIAgentVaultManager.sol#L231-L266


 - [ ] ID-65
[VaultShares._investInAdapters(IProtocolAdapter[],uint256[])](.contracts/protocol/VaultShares.sol#L181-L202) has external calls inside a loop: [vaultAdapters[i].invest(IERC20(asset()),amountToInvest)](.contracts/protocol/VaultShares.sol#L199)
	Calls stack containing the loop:
		VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[])

.contracts/protocol/VaultShares.sol#L181-L202


 - [ ] ID-66
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L316-L329) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L324)
	Calls stack containing the loop:
		ERC4626.previewRedeem(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L316-L329


 - [ ] ID-67
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L316-L329) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L324)
	Calls stack containing the loop:
		ERC4626.previewMint(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L316-L329


 - [ ] ID-68
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L316-L329) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L324)
	Calls stack containing the loop:
		ERC4626.convertToShares(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L316-L329


 - [ ] ID-69
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L316-L329) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L324)
	Calls stack containing the loop:
		VaultShares.deposit(uint256,address)
		ERC4626.previewDeposit(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L316-L329


 - [ ] ID-70
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L316-L329) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L324)
	Calls stack containing the loop:
		VaultShares.mint(uint256,address)
		ERC4626.previewMint(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L316-L329


 - [ ] ID-71
[VaultShares.withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L162-L176) has external calls inside a loop: [valueInAdapter = adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L169)
	Calls stack containing the loop:
		VaultShares.updateHoldingAllocation(IProtocolAdapter[],uint256[])

.contracts/protocol/VaultShares.sol#L162-L176


 - [ ] ID-72
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L316-L329) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L324)

.contracts/protocol/VaultShares.sol#L316-L329


 - [ ] ID-73
[VaultShares.withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L162-L176) has external calls inside a loop: [adapter.divest(IERC20(asset()),valueInAdapter)](.contracts/protocol/VaultShares.sol#L173)
	Calls stack containing the loop:
		VaultShares.updateHoldingAllocation(IProtocolAdapter[],uint256[])

.contracts/protocol/VaultShares.sol#L162-L176


 - [ ] ID-74
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L316-L329) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L324)
	Calls stack containing the loop:
		VaultShares.redeem(uint256,address,address)
		ERC4626.previewRedeem(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L316-L329


 - [ ] ID-75
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L316-L329) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L324)
	Calls stack containing the loop:
		ERC4626.maxWithdraw(address)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L316-L329


 - [ ] ID-76
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L316-L329) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L324)
	Calls stack containing the loop:
		ERC4626.previewWithdraw(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L316-L329


 - [ ] ID-77
[VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultShares.sol#L116-L157) has external calls inside a loop: [currentAdapters[divestAdapterIndices[i]].divest(IERC20(asset()),divestAmounts[i])](.contracts/protocol/VaultShares.sol#L138)

.contracts/protocol/VaultShares.sol#L116-L157


 - [ ] ID-78
[VaultShares._investInAdapters(IProtocolAdapter[],uint256[])](.contracts/protocol/VaultShares.sol#L181-L202) has external calls inside a loop: [vaultAdapters[i].invest(IERC20(asset()),amountToInvest)](.contracts/protocol/VaultShares.sol#L199)
	Calls stack containing the loop:
		VaultShares.updateHoldingAllocation(IProtocolAdapter[],uint256[])

.contracts/protocol/VaultShares.sol#L181-L202


 - [ ] ID-79
[VaultShares.withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L162-L176) has external calls inside a loop: [adapter.divest(IERC20(asset()),valueInAdapter)](.contracts/protocol/VaultShares.sol#L173)

.contracts/protocol/VaultShares.sol#L162-L176


 - [ ] ID-80
[VaultShares.withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L162-L176) has external calls inside a loop: [valueInAdapter = adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L169)

.contracts/protocol/VaultShares.sol#L162-L176


 - [ ] ID-81
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L316-L329) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L324)
	Calls stack containing the loop:
		ERC4626.previewDeposit(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L316-L329


 - [ ] ID-82
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L316-L329) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L324)
	Calls stack containing the loop:
		ERC4626.convertToAssets(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L316-L329


 - [ ] ID-83
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L316-L329) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L324)
	Calls stack containing the loop:
		VaultShares.withdraw(uint256,address,address)
		ERC4626.previewWithdraw(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L316-L329


## reentrancy-benign
Impact: Low
Confidence: Medium
 - [ ] ID-84
Reentrancy in [UniswapV3Adapter._investWithBalances(IERC20,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L570-L673):
	External calls:
	- [_swapToken(IERC20(token1Addr),IERC20(token0Addr),config.feeTier,amountToSwap,config.slippageTolerance)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L619-L625)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L379-L385)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L404)
	- [_swapToken(IERC20(token0Addr),IERC20(token1Addr),config.feeTier,amountToSwap_scope_0,config.slippageTolerance)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L631-L637)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L379-L385)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L404)
	- [(tokenId,liquidityMinted,amount0,amount1) = i_positionManager.mint(mintParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L669-L671)
	State variables written after the call(s):
	- [s_tokenConfigs[token].tokenId = tokenId](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L672)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L570-L673


## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-85
Reentrancy in [AIAgentVaultManager.partialUpdateHoldingAllocation(IERC20,uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/AIAgentVaultManager.sol#L113-L140):
	External calls:
	- [s_vault[token].partialUpdateHoldingAllocation(divestAdapterIndices,divestAmounts,investAdapterIndices,investAllocations)](.contracts/protocol/AIAgentVaultManager.sol#L135-L137)
	Event emitted after the call(s):
	- [AllocationUpdated(vaultAddress,investAllocations)](.contracts/protocol/AIAgentVaultManager.sol#L139)

.contracts/protocol/AIAgentVaultManager.sol#L113-L140


 - [ ] ID-86
Reentrancy in [UniswapV3Adapter._divest(IERC20,uint256,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L707-L744):
	External calls:
	- [_removeLiquidityAndCollectTokens(config,tokenId,SafeCast.toUint128(liquidityAmount))](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L719-L723)
		- [(amount0,amount1) = i_positionManager.decreaseLiquidity(decreaseParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L784-L786)
		- [i_positionManager.collect(collectParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L797)
	- [_swapToken(config.counterPartyToken,asset,config.feeTier,counterPartyTokenBalance,config.slippageTolerance)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L731-L737)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L379-L385)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L404)
	Event emitted after the call(s):
	- [UniswapV3Divested(address(asset),assetBalance)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L742)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L707-L744


 - [ ] ID-87
Reentrancy in [UniswapV3Adapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L681-L698):
	External calls:
	- [(liquidityMinted,amount0,amount1) = _investWithBalances(asset,config)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L684-L688)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L379-L385)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L404)
		- [(tokenId,liquidityMinted,amount0,amount1) = i_positionManager.mint(mintParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L669-L671)
	Event emitted after the call(s):
	- [UniswapV3Invested(address(asset),amount0,amount1,liquidityMinted)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L690-L695)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L681-L698


 - [ ] ID-88
Reentrancy in [UniswapAdapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L185-L238):
	External calls:
	- [actualTokenB = _swap(path,amountOfTokenToSwap,(i_uniswapRouter.getAmountsOut(amountOfTokenToSwap,path)[1] * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L195-L201)
		- [amounts = i_uniswapRouter.swapExactTokensForTokens({amountIn:amountIn,amountOutMin:minOut,path:path,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L349-L357)
	- [(tokenAmount,counterPartyTokenAmount,liquidity) = i_uniswapRouter.addLiquidity({tokenA:address(asset),tokenB:address(config.counterPartyToken),amountADesired:amountOfTokenToSwap,amountBDesired:actualTokenB,amountAMin:(amountOfTokenToSwap * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,amountBMin:(actualTokenB * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L212-L229)
	Event emitted after the call(s):
	- [UniswapInvested(address(asset),tokenAmount,counterPartyTokenAmount,liquidity)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L231-L236)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L185-L238


 - [ ] ID-89
Reentrancy in [UniswapAdapter._divest(IERC20,uint256,UniswapAdapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L270-L332):
	External calls:
	- [(tokenAmount,counterPartyAmount) = i_uniswapRouter.removeLiquidity({tokenA:address(asset),tokenB:address(config.counterPartyToken),liquidity:liquidityAmount,amountAMin:minToken,amountBMin:minCounter,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L300-L309)
	- [swapAmount = _swap(path,counterPartyAmount,minOut)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L326)
		- [amounts = i_uniswapRouter.swapExactTokensForTokens({amountIn:amountIn,amountOutMin:minOut,path:path,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L349-L357)
	Event emitted after the call(s):
	- [UniswapDivested(address(asset),tokenAmount,counterPartyAmount)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L330)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L270-L332


 - [ ] ID-90
Reentrancy in [UniswapAdapter.updateTokenConfigAndReinvest(IERC20,IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L116-L156):
	External calls:
	- [_divest(token,lpBalance,config)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L144)
		- [amounts = i_uniswapRouter.swapExactTokensForTokens({amountIn:amountIn,amountOutMin:minOut,path:path,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L349-L357)
		- [(tokenAmount,counterPartyAmount) = i_uniswapRouter.removeLiquidity({tokenA:address(asset),tokenB:address(config.counterPartyToken),liquidity:liquidityAmount,amountAMin:minToken,amountBMin:minCounter,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L300-L309)
	- [_invest(token,availableAssets)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L153)
		- [amounts = i_uniswapRouter.swapExactTokensForTokens({amountIn:amountIn,amountOutMin:minOut,path:path,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L349-L357)
		- [(tokenAmount,counterPartyTokenAmount,liquidity) = i_uniswapRouter.addLiquidity({tokenA:address(asset),tokenB:address(config.counterPartyToken),amountADesired:amountOfTokenToSwap,amountBDesired:actualTokenB,amountAMin:(amountOfTokenToSwap * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,amountBMin:(actualTokenB * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L212-L229)
	Event emitted after the call(s):
	- [TokenConfigUpdated(address(token))](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L155)
	- [UniswapInvested(address(asset),tokenAmount,counterPartyTokenAmount,liquidity)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L231-L236)
		- [_invest(token,availableAssets)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L153)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L116-L156


 - [ ] ID-91
Reentrancy in [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241):
	External calls:
	- [_divest(token,liquidity,config)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L207)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L379-L385)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L404)
		- [(amount0,amount1) = i_positionManager.decreaseLiquidity(decreaseParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L784-L786)
		- [i_positionManager.collect(collectParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L797)
	- [_invest(token,availableAssets)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L237)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L379-L385)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L404)
		- [(tokenId,liquidityMinted,amount0,amount1) = i_positionManager.mint(mintParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L669-L671)
	Event emitted after the call(s):
	- [TokenConfigUpdated(address(token))](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L240)
	- [UniswapV3Invested(address(asset),amount0,amount1,liquidityMinted)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L690-L695)
		- [_invest(token,availableAssets)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L237)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241


 - [ ] ID-92
Reentrancy in [AIAgentVaultManager.execute(uint256,uint256,bytes)](.contracts/protocol/AIAgentVaultManager.sol#L200-L222):
	External calls:
	- [(success,result) = address(adapter).call{value: value}(data)](.contracts/protocol/AIAgentVaultManager.sol#L214)
	Event emitted after the call(s):
	- [AdapterExecuted(address(adapter),value,data,result)](.contracts/protocol/AIAgentVaultManager.sol#L220)

.contracts/protocol/AIAgentVaultManager.sol#L200-L222


 - [ ] ID-93
Reentrancy in [VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultShares.sol#L116-L157):
	External calls:
	- [currentAdapters[divestAdapterIndices[i]].divest(IERC20(asset()),divestAmounts[i])](.contracts/protocol/VaultShares.sol#L138)
	- [_investInAdapters(investAdapters,investAllocations)](.contracts/protocol/VaultShares.sol#L154)
		- [vaultAdapters[i].invest(IERC20(asset()),amountToInvest)](.contracts/protocol/VaultShares.sol#L199)
	Event emitted after the call(s):
	- [HoldingAllocationUpdated(investAdapters,investAllocations)](.contracts/protocol/VaultShares.sol#L156)

.contracts/protocol/VaultShares.sol#L116-L157


 - [ ] ID-94
Reentrancy in [AIAgentVaultManager.updateHoldingAllocation(IERC20,uint256[],uint256[])](.contracts/protocol/AIAgentVaultManager.sol#L76-L103):
	External calls:
	- [s_vault[token].updateHoldingAllocation(selectedAdapters,allocationData)](.contracts/protocol/AIAgentVaultManager.sol#L100)
	Event emitted after the call(s):
	- [AllocationUpdated(vaultAddress,allocationData)](.contracts/protocol/AIAgentVaultManager.sol#L102)

.contracts/protocol/AIAgentVaultManager.sol#L76-L103


 - [ ] ID-95
Reentrancy in [VaultShares.updateHoldingAllocation(IProtocolAdapter[],uint256[])](.contracts/protocol/VaultShares.sol#L92-L107):
	External calls:
	- [withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L98)
		- [adapter.divest(IERC20(asset()),valueInAdapter)](.contracts/protocol/VaultShares.sol#L173)
	- [_investInAdapters(vaultAdapters,allocationData)](.contracts/protocol/VaultShares.sol#L101)
		- [vaultAdapters[i].invest(IERC20(asset()),amountToInvest)](.contracts/protocol/VaultShares.sol#L199)
	Event emitted after the call(s):
	- [HoldingAllocationUpdated(vaultAdapters,allocationData)](.contracts/protocol/VaultShares.sol#L106)

.contracts/protocol/VaultShares.sol#L92-L107


 - [ ] ID-96
Reentrancy in [AIAgentVaultManager.executeBatch(uint256[],uint256[],bytes[])](.contracts/protocol/AIAgentVaultManager.sol#L231-L266):
	External calls:
	- [(success,result) = target.call{value: values[i]}(data[i])](.contracts/protocol/AIAgentVaultManager.sol#L258)
	Event emitted after the call(s):
	- [AdapterExecuted(target,values[i],data[i],returnData[i])](.contracts/protocol/AIAgentVaultManager.sol#L264)

.contracts/protocol/AIAgentVaultManager.sol#L231-L266


 - [ ] ID-97
Reentrancy in [AIAgentVaultManager.setVaultNotActive(IERC20)](.contracts/protocol/AIAgentVaultManager.sol#L160-L170):
	External calls:
	- [s_vault[token].setNotActive()](.contracts/protocol/AIAgentVaultManager.sol#L167)
	Event emitted after the call(s):
	- [VaultEmergencyStopped(vaultAddress)](.contracts/protocol/AIAgentVaultManager.sol#L169)

.contracts/protocol/AIAgentVaultManager.sol#L160-L170


 - [ ] ID-98
Reentrancy in [UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319):
	External calls:
	- [_removeLiquidityAndCollectTokens(config,config.tokenId,liquidity)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L276-L280)
		- [(amount0,amount1) = i_positionManager.decreaseLiquidity(decreaseParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L784-L786)
		- [i_positionManager.collect(collectParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L797)
	- [i_positionManager.burn(config.tokenId)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L299)
	- [(liquidityMinted,newAmount0,newAmount1) = _investWithBalances(token,config)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L307-L311)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L379-L385)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L404)
		- [(tokenId,liquidityMinted,amount0,amount1) = i_positionManager.mint(mintParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L669-L671)
	Event emitted after the call(s):
	- [UniswapV3Invested(address(token),newAmount0,newAmount1,liquidityMinted)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L313-L318)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-99
[UniswapAdapter._divest(IERC20,uint256,UniswapAdapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L270-L332) uses timestamp for comparisons
	Dangerous comparisons:
	- [counterPartyAmount > 0](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L312)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L270-L332


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-100
[WadRayMath.rayMul(uint256,uint256)](.contracts/vendor/AaveV3/WadRayMath.sol#L61-L68) uses assembly
	- [INLINE ASM](.contracts/vendor/AaveV3/WadRayMath.sol#L63-L67)

.contracts/vendor/AaveV3/WadRayMath.sol#L61-L68


 - [ ] ID-101
[Math.tryMul(uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L73-L84) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L76-L80)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L73-L84


 - [ ] ID-102
[WadRayMath.rayToWad(uint256)](.contracts/vendor/AaveV3/WadRayMath.sol#L92-L98) uses assembly
	- [INLINE ASM](.contracts/vendor/AaveV3/WadRayMath.sol#L93-L97)

.contracts/vendor/AaveV3/WadRayMath.sol#L92-L98


 - [ ] ID-103
[Math.mul512(uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L37-L46) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L41-L45)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L37-L46


 - [ ] ID-104
[TickMath.getTickAtSqrtRatio(uint160)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L99-L242) uses assembly
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L107-L111)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L112-L116)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L117-L121)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L122-L126)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L127-L131)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L132-L136)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L137-L141)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L142-L145)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L152-L157)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L158-L163)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L164-L169)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L170-L175)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L176-L181)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L182-L187)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L188-L193)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L194-L199)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L200-L205)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L206-L211)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L212-L217)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L218-L223)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L224-L229)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L230-L234)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L99-L242


 - [ ] ID-105
[Math.add512(uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L25-L30) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L26-L29)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L25-L30


 - [ ] ID-106
[SafeCast.toUint(bool)](.lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L1157-L1161) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L1158-L1160)

.lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L1157-L1161


 - [ ] ID-107
[WadRayMath.wadDiv(uint256,uint256)](.contracts/vendor/AaveV3/WadRayMath.sol#L45-L52) uses assembly
	- [INLINE ASM](.contracts/vendor/AaveV3/WadRayMath.sol#L47-L51)

.contracts/vendor/AaveV3/WadRayMath.sol#L45-L52


 - [ ] ID-108
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) uses assembly
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L23-L26)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L34-L36)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L47-L49)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L51-L54)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L61-L63)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L66-L68)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L72-L74)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-109
[SafeERC20._callOptionalReturn(IERC20,bytes)](.lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L173-L191) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L176-L186)

.lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L173-L191


 - [ ] ID-110
[WadRayMath.rayDiv(uint256,uint256)](.contracts/vendor/AaveV3/WadRayMath.sol#L77-L84) uses assembly
	- [INLINE ASM](.contracts/vendor/AaveV3/WadRayMath.sol#L79-L83)

.contracts/vendor/AaveV3/WadRayMath.sol#L77-L84


 - [ ] ID-111
[Math.log2(uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L612-L651) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L648-L650)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L612-L651


 - [ ] ID-112
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L227-L234)
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L240-L249)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-113
[Panic.panic(uint256)](.lib/openzeppelin-contracts/contracts/utils/Panic.sol#L50-L56) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/Panic.sol#L51-L55)

.lib/openzeppelin-contracts/contracts/utils/Panic.sol#L50-L56


 - [ ] ID-114
[WadRayMath.wadMul(uint256,uint256)](.contracts/vendor/AaveV3/WadRayMath.sol#L29-L36) uses assembly
	- [INLINE ASM](.contracts/vendor/AaveV3/WadRayMath.sol#L31-L35)

.contracts/vendor/AaveV3/WadRayMath.sol#L29-L36


 - [ ] ID-115
[Math.tryMod(uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L102-L110) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L105-L108)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L102-L110


 - [ ] ID-116
[Math.tryDiv(uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L89-L97) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L92-L95)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L89-L97


 - [ ] ID-117
[Math.tryModExp(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L409-L433) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L411-L432)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L409-L433


 - [ ] ID-118
[WadRayMath.wadToRay(uint256)](.contracts/vendor/AaveV3/WadRayMath.sol#L106-L113) uses assembly
	- [INLINE ASM](.contracts/vendor/AaveV3/WadRayMath.sol#L108-L112)

.contracts/vendor/AaveV3/WadRayMath.sol#L106-L113


 - [ ] ID-119
[SafeERC20._callOptionalReturnBool(IERC20,bytes)](.lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L201-L211) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L205-L209)

.lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L201-L211


 - [ ] ID-120
[Math.tryModExp(bytes,bytes,bytes)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L449-L471) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L461-L470)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L449-L471


## pragma
Impact: Informational
Confidence: High
 - [ ] ID-121
9 different versions of Solidity are used:
	- Version constraint ^0.8.25 is used by:
		-[^0.8.25](.contracts/abstract/AStaticUSDCData.sol#L2)
		-[^0.8.25](.contracts/abstract/AStaticUSDTData.sol#L2)
		-[^0.8.25](.contracts/interfaces/IProtocolAdapter.sol#L2)
		-[^0.8.25](.contracts/interfaces/IVaultShares.sol#L2)
		-[^0.8.25](.contracts/protocol/AIAgentVaultManager.sol#L2)
		-[^0.8.25](.contracts/protocol/VaultShares.sol#L2)
		-[^0.8.25](.contracts/protocol/investableUniverseAdapters/AaveAdapter.sol#L2)
		-[^0.8.25](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L2)
		-[^0.8.25](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L2)
		-[^0.8.25](.contracts/vendor/AaveV3/DataTypes.sol#L2)
		-[^0.8.25](.contracts/vendor/AaveV3/IPool.sol#L2)
		-[^0.8.25](.contracts/vendor/UniswapV2/IUniswapV2Factory.sol#L2)
		-[^0.8.25](.contracts/vendor/UniswapV2/IUniswapV2Router01.sol#L2)
	- Version constraint ^0.8.0 is used by:
		-[^0.8.0](.contracts/vendor/AaveV3/WadRayMath.sol#L2)
		-[^0.8.0](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L2)
	- Version constraint >=0.5.0 is used by:
		-[>=0.5.0](.contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L2)
		-[>=0.5.0](.contracts/vendor/UniswapV3/core/IUniswapV3Factory.sol#L2)
		-[>=0.5.0](.contracts/vendor/UniswapV3/core/IUniswapV3Pool.sol#L2)
		-[>=0.5.0](.contracts/vendor/UniswapV3/core/IUniswapV3SwapCallback.sol#L2)
		-[>=0.5.0](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L2)
		-[>=0.5.0](.contracts/vendor/UniswapV3/core/pool/IUniswapV3PoolActions.sol#L2)
		-[>=0.5.0](.contracts/vendor/UniswapV3/core/pool/IUniswapV3PoolDerivedState.sol#L2)
		-[>=0.5.0](.contracts/vendor/UniswapV3/core/pool/IUniswapV3PoolEvents.sol#L2)
		-[>=0.5.0](.contracts/vendor/UniswapV3/core/pool/IUniswapV3PoolImmutables.sol#L2)
		-[>=0.5.0](.contracts/vendor/UniswapV3/core/pool/IUniswapV3PoolOwnerActions.sol#L2)
		-[>=0.5.0](.contracts/vendor/UniswapV3/core/pool/IUniswapV3PoolState.sol#L2)
		-[>=0.5.0](.contracts/vendor/UniswapV3/periphery/LiquidityAmounts.sol#L2)
		-[>=0.5.0](.contracts/vendor/UniswapV3/periphery/interfaces/IPeripheryImmutableState.sol#L2)
	- Version constraint >=0.4.0 is used by:
		-[>=0.4.0](.contracts/vendor/UniswapV3/core/libraries/FixedPoint96.sol#L2)
	- Version constraint >=0.7.5 is used by:
		-[>=0.7.5](.contracts/vendor/UniswapV3/periphery/interfaces/IERC721Permit.sol#L2)
		-[>=0.7.5](.contracts/vendor/UniswapV3/periphery/interfaces/INonfungiblePositionManager.sol#L2)
		-[>=0.7.5](.contracts/vendor/UniswapV3/periphery/interfaces/IPeripheryPayments.sol#L2)
		-[>=0.7.5](.contracts/vendor/UniswapV3/periphery/interfaces/IPoolInitializer.sol#L2)
		-[>=0.7.5](.contracts/vendor/UniswapV3/periphery/interfaces/IQuoter.sol#L2)
		-[>=0.7.5](.contracts/vendor/UniswapV3/periphery/interfaces/ISwapRouter.sol#L2)
	- Version constraint ^0.8.20 is used by:
		-[^0.8.20](.lib/openzeppelin-contracts/contracts/access/Ownable.sol#L4)
		-[^0.8.20](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L4)
		-[^0.8.20](.lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L4)
		-[^0.8.20](.lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L4)
		-[^0.8.20](.lib/openzeppelin-contracts/contracts/utils/Context.sol#L4)
		-[^0.8.20](.lib/openzeppelin-contracts/contracts/utils/Panic.sol#L4)
		-[^0.8.20](.lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol#L4)
		-[^0.8.20](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L4)
		-[^0.8.20](.lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L5)
	- Version constraint >=0.6.2 is used by:
		-[>=0.6.2](.lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#L4)
		-[>=0.6.2](.lib/openzeppelin-contracts/contracts/interfaces/IERC4626.sol#L4)
		-[>=0.6.2](.lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol#L4)
		-[>=0.6.2](.lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol#L4)
		-[>=0.6.2](.lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol#L4)
		-[>=0.6.2](.lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol#L4)
	- Version constraint >=0.4.16 is used by:
		-[>=0.4.16](.lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#L4)
		-[>=0.4.16](.lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol#L4)
		-[>=0.4.16](.lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol#L4)
		-[>=0.4.16](.lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#L4)
	- Version constraint >=0.8.4 is used by:
		-[>=0.8.4](.lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#L3)

.contracts/abstract/AStaticUSDCData.sol#L2


## cyclomatic-complexity
Impact: Informational
Confidence: High
 - [ ] ID-122
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) has a high cyclomatic complexity (24).

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


## solc-version
Impact: Informational
Confidence: High
 - [ ] ID-123
Version constraint >=0.6.2 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- MissingSideEffectsOnSelectorAccess
	- AbiReencodingHeadOverflowWithStaticArrayCleanup
	- DirtyBytesArrayToStorage
	- NestedCalldataArrayAbiReencodingSizeValidation
	- ABIDecodeTwoDimensionalArrayMemory
	- KeccakCaching
	- EmptyByteArrayCopy
	- DynamicArrayCleanup
	- MissingEscapingInFormatting
	- ArraySliceDynamicallyEncodedBaseType
	- ImplicitConstructorCallvalueCheck
	- TupleAssignmentMultiStackSlotComponents
	- MemoryArrayCreationOverflow.
It is used by:
	- [>=0.6.2](.lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#L4)
	- [>=0.6.2](.lib/openzeppelin-contracts/contracts/interfaces/IERC4626.sol#L4)
	- [>=0.6.2](.lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol#L4)
	- [>=0.6.2](.lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol#L4)
	- [>=0.6.2](.lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol#L4)
	- [>=0.6.2](.lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol#L4)

.lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#L4


 - [ ] ID-124
Version constraint >=0.4.0 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- DirtyBytesArrayToStorage
	- KeccakCaching
	- EmptyByteArrayCopy
	- DynamicArrayCleanup
	- TupleAssignmentMultiStackSlotComponents
	- MemoryArrayCreationOverflow
	- privateCanBeOverridden
	- IncorrectEventSignatureInLibraries_0.4.x
	- ExpExponentCleanup
	- NestedArrayFunctionCallDecoder
	- ZeroFunctionSelector
	- DelegateCallReturnValue
	- ECRecoverMalformedInput
	- SkipEmptyStringLiteral
	- ConstantOptimizerSubtraction
	- IdentityPrecompileReturnIgnored
	- HighOrderByteCleanStorage
	- OptimizerStaleKnowledgeAboutSHA3
	- LibrariesNotCallableFromPayableFunctions.
It is used by:
	- [>=0.4.0](.contracts/vendor/UniswapV3/core/libraries/FixedPoint96.sol#L2)

.contracts/vendor/UniswapV3/core/libraries/FixedPoint96.sol#L2


 - [ ] ID-125
Version constraint >=0.5.0 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- DirtyBytesArrayToStorage
	- ABIDecodeTwoDimensionalArrayMemory
	- KeccakCaching
	- EmptyByteArrayCopy
	- DynamicArrayCleanup
	- ImplicitConstructorCallvalueCheck
	- TupleAssignmentMultiStackSlotComponents
	- MemoryArrayCreationOverflow
	- privateCanBeOverridden
	- SignedArrayStorageCopy
	- ABIEncoderV2StorageArrayWithMultiSlotElement
	- DynamicConstructorArgumentsClippedABIV2
	- UninitializedFunctionPointerInConstructor
	- IncorrectEventSignatureInLibraries
	- ABIEncoderV2PackedStorage.
It is used by:
	- [>=0.5.0](.contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L2)
	- [>=0.5.0](.contracts/vendor/UniswapV3/core/IUniswapV3Factory.sol#L2)
	- [>=0.5.0](.contracts/vendor/UniswapV3/core/IUniswapV3Pool.sol#L2)
	- [>=0.5.0](.contracts/vendor/UniswapV3/core/IUniswapV3SwapCallback.sol#L2)
	- [>=0.5.0](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L2)
	- [>=0.5.0](.contracts/vendor/UniswapV3/core/pool/IUniswapV3PoolActions.sol#L2)
	- [>=0.5.0](.contracts/vendor/UniswapV3/core/pool/IUniswapV3PoolDerivedState.sol#L2)
	- [>=0.5.0](.contracts/vendor/UniswapV3/core/pool/IUniswapV3PoolEvents.sol#L2)
	- [>=0.5.0](.contracts/vendor/UniswapV3/core/pool/IUniswapV3PoolImmutables.sol#L2)
	- [>=0.5.0](.contracts/vendor/UniswapV3/core/pool/IUniswapV3PoolOwnerActions.sol#L2)
	- [>=0.5.0](.contracts/vendor/UniswapV3/core/pool/IUniswapV3PoolState.sol#L2)
	- [>=0.5.0](.contracts/vendor/UniswapV3/periphery/LiquidityAmounts.sol#L2)
	- [>=0.5.0](.contracts/vendor/UniswapV3/periphery/interfaces/IPeripheryImmutableState.sol#L2)

.contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L2


 - [ ] ID-126
Version constraint >=0.8.4 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess
	- AbiReencodingHeadOverflowWithStaticArrayCleanup
	- DirtyBytesArrayToStorage
	- DataLocationChangeInInternalOverride
	- NestedCalldataArrayAbiReencodingSizeValidation
	- SignedImmutables.
It is used by:
	- [>=0.8.4](.lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#L3)

.lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#L3


 - [ ] ID-127
Version constraint >=0.4.16 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- DirtyBytesArrayToStorage
	- ABIDecodeTwoDimensionalArrayMemory
	- KeccakCaching
	- EmptyByteArrayCopy
	- DynamicArrayCleanup
	- ImplicitConstructorCallvalueCheck
	- TupleAssignmentMultiStackSlotComponents
	- MemoryArrayCreationOverflow
	- privateCanBeOverridden
	- SignedArrayStorageCopy
	- ABIEncoderV2StorageArrayWithMultiSlotElement
	- DynamicConstructorArgumentsClippedABIV2
	- UninitializedFunctionPointerInConstructor_0.4.x
	- IncorrectEventSignatureInLibraries_0.4.x
	- ExpExponentCleanup
	- NestedArrayFunctionCallDecoder
	- ZeroFunctionSelector.
It is used by:
	- [>=0.4.16](.lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#L4)
	- [>=0.4.16](.lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol#L4)
	- [>=0.4.16](.lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol#L4)
	- [>=0.4.16](.lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#L4)

.lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#L4


 - [ ] ID-128
Version constraint ^0.8.20 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess.
It is used by:
	- [^0.8.20](.lib/openzeppelin-contracts/contracts/access/Ownable.sol#L4)
	- [^0.8.20](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L4)
	- [^0.8.20](.lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L4)
	- [^0.8.20](.lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L4)
	- [^0.8.20](.lib/openzeppelin-contracts/contracts/utils/Context.sol#L4)
	- [^0.8.20](.lib/openzeppelin-contracts/contracts/utils/Panic.sol#L4)
	- [^0.8.20](.lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol#L4)
	- [^0.8.20](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L4)
	- [^0.8.20](.lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L5)

.lib/openzeppelin-contracts/contracts/access/Ownable.sol#L4


 - [ ] ID-129
Version constraint >=0.7.5 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess
	- AbiReencodingHeadOverflowWithStaticArrayCleanup
	- DirtyBytesArrayToStorage
	- DataLocationChangeInInternalOverride
	- NestedCalldataArrayAbiReencodingSizeValidation
	- SignedImmutables
	- ABIDecodeTwoDimensionalArrayMemory
	- KeccakCaching.
It is used by:
	- [>=0.7.5](.contracts/vendor/UniswapV3/periphery/interfaces/IERC721Permit.sol#L2)
	- [>=0.7.5](.contracts/vendor/UniswapV3/periphery/interfaces/INonfungiblePositionManager.sol#L2)
	- [>=0.7.5](.contracts/vendor/UniswapV3/periphery/interfaces/IPeripheryPayments.sol#L2)
	- [>=0.7.5](.contracts/vendor/UniswapV3/periphery/interfaces/IPoolInitializer.sol#L2)
	- [>=0.7.5](.contracts/vendor/UniswapV3/periphery/interfaces/IQuoter.sol#L2)
	- [>=0.7.5](.contracts/vendor/UniswapV3/periphery/interfaces/ISwapRouter.sol#L2)

.contracts/vendor/UniswapV3/periphery/interfaces/IERC721Permit.sol#L2


 - [ ] ID-130
Version constraint ^0.8.0 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess
	- AbiReencodingHeadOverflowWithStaticArrayCleanup
	- DirtyBytesArrayToStorage
	- DataLocationChangeInInternalOverride
	- NestedCalldataArrayAbiReencodingSizeValidation
	- SignedImmutables
	- ABIDecodeTwoDimensionalArrayMemory
	- KeccakCaching.
It is used by:
	- [^0.8.0](.contracts/vendor/AaveV3/WadRayMath.sol#L2)
	- [^0.8.0](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L2)

.contracts/vendor/AaveV3/WadRayMath.sol#L2


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-131
Low level call in [AIAgentVaultManager.executeBatch(uint256[],uint256[],bytes[])](.contracts/protocol/AIAgentVaultManager.sol#L231-L266):
	- [(success,result) = target.call{value: values[i]}(data[i])](.contracts/protocol/AIAgentVaultManager.sol#L258)

.contracts/protocol/AIAgentVaultManager.sol#L231-L266


 - [ ] ID-132
Low level call in [AIAgentVaultManager.execute(uint256,uint256,bytes)](.contracts/protocol/AIAgentVaultManager.sol#L200-L222):
	- [(success,result) = address(adapter).call{value: value}(data)](.contracts/protocol/AIAgentVaultManager.sol#L214)

.contracts/protocol/AIAgentVaultManager.sol#L200-L222


 - [ ] ID-133
Low level call in [ERC4626._tryGetAssetDecimals(IERC20)](.lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L86-L97):
	- [(success,encodedDecimals) = address(asset_).staticcall(abi.encodeCall(IERC20Metadata.decimals,()))](.lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L87-L89)

.lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L86-L97


## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-134
Parameter [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address).VaultAddress](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L100) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L100


 - [ ] ID-135
Function [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L171-L241


 - [ ] ID-136
Function [UniswapV3Adapter.UpdateTokenFeeTierAndPriceRange(IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L250-L319


 - [ ] ID-137
Function [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L146-L161) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L146-L161


 - [ ] ID-138
Variable [VaultShares.i_Fee](.contracts/protocol/VaultShares.sol#L40) is not in mixedCase

.contracts/protocol/VaultShares.sol#L40


 - [ ] ID-139
Variable [AaveAdapter.i_aavePool](.contracts/protocol/investableUniverseAdapters/AaveAdapter.sol#L18) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/AaveAdapter.sol#L18


 - [ ] ID-140
Function [IUniswapV2Pair.PERMIT_TYPEHASH()](.contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L28) is not in mixedCase

.contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L28


 - [ ] ID-141
Function [IUniswapV2Pair.MINIMUM_LIQUIDITY()](.contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L47) is not in mixedCase

.contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L47


 - [ ] ID-142
Function [IERC721Permit.PERMIT_TYPEHASH()](.contracts/vendor/UniswapV3/periphery/interfaces/IERC721Permit.sol#L11) is not in mixedCase

.contracts/vendor/UniswapV3/periphery/interfaces/IERC721Permit.sol#L11


 - [ ] ID-143
Function [IUniswapV2Pair.DOMAIN_SEPARATOR()](.contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L26) is not in mixedCase

.contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L26


 - [ ] ID-144
Variable [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L57


 - [ ] ID-145
Function [IPeripheryImmutableState.WETH9()](.contracts/vendor/UniswapV3/periphery/interfaces/IPeripheryImmutableState.sol#L11) is not in mixedCase

.contracts/vendor/UniswapV3/periphery/interfaces/IPeripheryImmutableState.sol#L11


 - [ ] ID-146
Function [IERC721Permit.DOMAIN_SEPARATOR()](.contracts/vendor/UniswapV3/periphery/interfaces/IERC721Permit.sol#L15) is not in mixedCase

.contracts/vendor/UniswapV3/periphery/interfaces/IERC721Permit.sol#L15


 - [ ] ID-147
Variable [UniswapAdapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L33) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L33


 - [ ] ID-148
Function [IUniswapV2Router01.WETH()](.contracts/vendor/UniswapV2/IUniswapV2Router01.sol#L9) is not in mixedCase

.contracts/vendor/UniswapV2/IUniswapV2Router01.sol#L9


 - [ ] ID-149
Constant [AIAgentVaultManager.s_Fee](.contracts/protocol/AIAgentVaultManager.sol#L26) is not in UPPER_CASE_WITH_UNDERSCORES

.contracts/protocol/AIAgentVaultManager.sol#L26


 - [ ] ID-150
Parameter [UniswapAdapter.setTokenConfig(IERC20,uint256,IERC20,address).VaultAddress](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L65) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L65


 - [ ] ID-151
Variable [AStaticUSDCData.i_USDC](.contracts/abstract/AStaticUSDCData.sol#L9) is not in mixedCase

.contracts/abstract/AStaticUSDCData.sol#L9


 - [ ] ID-152
Function [UniswapAdapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L93-L109) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L93-L109


## too-many-digits
Impact: Informational
Confidence: Medium
 - [ ] ID-153
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) uses literals with too many digits:
	- [ratio = 0x100000000000000000000000000000000](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L27)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-154
[Math.log2(uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L612-L651) uses literals with too many digits:
	- [r = r | byte(uint256,uint256)(x >> r,0x0000010102020202030303030303030300000000000000000000000000000000)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L649)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L612-L651


 - [ ] ID-155
[FixedPoint96.slitherConstructorConstantVariables()](.contracts/vendor/UniswapV3/core/libraries/FixedPoint96.sol#L7-L10) uses literals with too many digits:
	- [Q96 = 0x1000000000000000000000000](.contracts/vendor/UniswapV3/core/libraries/FixedPoint96.sol#L9)

.contracts/vendor/UniswapV3/core/libraries/FixedPoint96.sol#L7-L10


