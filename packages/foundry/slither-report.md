**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [arbitrary-send-eth](#arbitrary-send-eth) (1 results) (High)
 - [incorrect-exp](#incorrect-exp) (2 results) (High)
 - [divide-before-multiply](#divide-before-multiply) (47 results) (Medium)
 - [incorrect-equality](#incorrect-equality) (4 results) (Medium)
 - [reentrancy-no-eth](#reentrancy-no-eth) (12 results) (Medium)
 - [unused-return](#unused-return) (24 results) (Medium)
 - [missing-zero-check](#missing-zero-check) (2 results) (Low)
 - [calls-loop](#calls-loop) (53 results) (Low)
 - [reentrancy-benign](#reentrancy-benign) (7 results) (Low)
 - [reentrancy-events](#reentrancy-events) (11 results) (Low)
 - [timestamp](#timestamp) (1 results) (Low)
 - [assembly](#assembly) (23 results) (Informational)
 - [pragma](#pragma) (1 results) (Informational)
 - [cyclomatic-complexity](#cyclomatic-complexity) (2 results) (Informational)
 - [solc-version](#solc-version) (9 results) (Informational)
 - [low-level-calls](#low-level-calls) (5 results) (Informational)
 - [naming-convention](#naming-convention) (22 results) (Informational)
 - [too-many-digits](#too-many-digits) (7 results) (Informational)
## arbitrary-send-eth
Impact: High
Confidence: Medium
 - [ ] ID-0
[VaultSharesETH.withdrawETH(uint256,address,address)](.contracts/protocol/VaultSharesETH.sol#L290-L326) sends eth to arbitrary user
	Dangerous calls:
	- [(success,None) = receiver.call{value: assets}()](.contracts/protocol/VaultSharesETH.sol#L322)

.contracts/protocol/VaultSharesETH.sol#L290-L326


## incorrect-exp
Impact: High
Confidence: Medium
 - [ ] ID-1
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) has bitwise-xor operator ^ instead of the exponentiation operator **: 
	 - [inv = (3 * denominator) ^ 2](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L82)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-2
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) has bitwise-xor operator ^ instead of the exponentiation operator **: 
	 - [inverse = (3 * denominator) ^ 2](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L257)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


## divide-before-multiply
Impact: Medium
Confidence: Medium
 - [ ] ID-3
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L47)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-4
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [prod0 = prod0 / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L67)
	- [result = prod0 * inv](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L99)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-5
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L62)
	- [inv *= 2 - denominator * inv](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-6
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L77)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-7
[UniswapV2Adapter._divest(IERC20,uint256,UniswapV2Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323) performs a multiplication on the result of a division:
	- [liquidityToRemove = (lpBalance * tokenAmount) / currentAssetValue](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L272)
	- [amount1 = (uint256(reserve1) * liquidityToRemove) / totalSupply](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L276)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323


 - [ ] ID-8
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L32)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-9
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L62)
	- [inv *= 2 - denominator * inv](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L89)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-10
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L265)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-11
[UniswapV2Adapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L175-L212) performs a multiplication on the result of a division:
	- [amountOfTokenToSwap = amount / 2](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L177)
	- [(tokenAmount,counterPartyTokenAmount,liquidity) = i_uniswapRouter.addLiquidity({tokenA:address(asset),tokenB:address(config.counterPartyToken),amountADesired:amountOfTokenToSwap,amountBDesired:actualTokenB,amountAMin:(amountOfTokenToSwap * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,amountBMin:(actualTokenB * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L199-L208)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L175-L212


 - [ ] ID-12
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L65)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-13
[UniswapV2Adapter.getTotalValue(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L348-L372) performs a multiplication on the result of a division:
	- [amount0 = (uint256(reserve0) * liquidityTokens) / totalSupply](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L361)
	- [amount1 + (amount0 * reserve1) / reserve0](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L368)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L348-L372


 - [ ] ID-14
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L80)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-15
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L41)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-16
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse = (3 * denominator) ^ 2](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L257)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-17
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L62)
	- [inv *= 2 - denominator * inv](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L91)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-18
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L38)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-19
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L35)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-20
[UniswapV3Adapter._calculateV3OptimalSwapAmount(uint256,uint160,uint160,uint160,bool)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L664-L741) performs a multiplication on the result of a division:
	- [token0Ratio = (numerator_scope_0 * 1000000) / denominator_scope_1](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L723)
	- [amountToKeep_scope_2 = (totalAmount * token0Ratio) / 1000000](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L724)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L664-L741


 - [ ] ID-21
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [low = low / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L245)
	- [result = low * inverse](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L272)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-22
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L62)
	- [inv *= 2 - denominator * inv](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L87)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-23
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L62)
	- [inv *= 2 - denominator * inv](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L88)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-24
[Math.invMod(uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L315-L361) performs a multiplication on the result of a division:
	- [quotient = gcd / remainder](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L337)
	- [(gcd,remainder) = (remainder,gcd - remainder * quotient)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L339-L346)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L315-L361


 - [ ] ID-25
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L56)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-26
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L59)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-27
[UniswapV2Adapter._divest(IERC20,uint256,UniswapV2Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323) performs a multiplication on the result of a division:
	- [amount0 = (uint256(reserve0) * liquidityToRemove) / totalSupply](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L275)
	- [amountBMin = (amount0 * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L293)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323


 - [ ] ID-28
[UniswapV2Adapter.getTotalValue(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L348-L372) performs a multiplication on the result of a division:
	- [amount1 = (uint256(reserve1) * liquidityTokens) / totalSupply](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L362)
	- [amount0 + (amount1 * reserve0) / reserve1](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L366)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L348-L372


 - [ ] ID-29
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L62)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-30
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L263)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-31
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L261)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-32
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L29)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-33
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L266)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-34
[UniswapV3Adapter._calculateV3OptimalSwapAmount(uint256,uint160,uint160,uint160,bool)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L664-L741) performs a multiplication on the result of a division:
	- [token1Ratio = (numerator * 1000000) / denominator](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L691)
	- [amountToKeep = (totalAmount * token1Ratio) / 1000000](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L692)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L664-L741


 - [ ] ID-35
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L62)
	- [inv *= 2 - denominator * inv](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L90)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-36
[UniswapV2Adapter._divest(IERC20,uint256,UniswapV2Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323) performs a multiplication on the result of a division:
	- [liquidityToRemove = (lpBalance * tokenAmount) / currentAssetValue](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L272)
	- [amount0 = (uint256(reserve0) * liquidityToRemove) / totalSupply](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L275)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323


 - [ ] ID-37
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L264)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-38
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L74)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-39
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L50)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-40
[UniswapV2Adapter._divest(IERC20,uint256,UniswapV2Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323) performs a multiplication on the result of a division:
	- [amount1 = (uint256(reserve1) * liquidityToRemove) / totalSupply](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L276)
	- [amountAMin = (amount1 * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L292)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323


 - [ ] ID-41
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L62)
	- [inv = (3 * denominator) ^ 2](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L82)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-42
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L83)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-43
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L44)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-44
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L68)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-45
[UniswapV2Adapter._divest(IERC20,uint256,UniswapV2Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323) performs a multiplication on the result of a division:
	- [amount1 = (uint256(reserve1) * liquidityToRemove) / totalSupply](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L276)
	- [amountBMin = (amount1 * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L289)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323


 - [ ] ID-46
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L262)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-47
[UniswapV2Adapter._divest(IERC20,uint256,UniswapV2Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323) performs a multiplication on the result of a division:
	- [amount0 = (uint256(reserve0) * liquidityToRemove) / totalSupply](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L275)
	- [amountAMin = (amount0 * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L288)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323


 - [ ] ID-48
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L53)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-49
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) performs a multiplication on the result of a division:
	- [ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L71)
	- [ratio = type()(uint256).max / ratio](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L86)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


## incorrect-equality
Impact: Medium
Confidence: High
 - [ ] ID-50
[UniswapV3Adapter._investWithBalances(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L408-L497) uses a dangerous strict equality:
	- [balance0 == 0 && balance1 > 0](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L426)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L408-L497


 - [ ] ID-51
[UniswapV2Adapter._divest(IERC20,uint256,UniswapV2Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323) uses a dangerous strict equality:
	- [lpBalance == 0](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L251)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323


 - [ ] ID-52
[UniswapV3Adapter._investWithBalances(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L408-L497) uses a dangerous strict equality:
	- [balance1 == 0 && balance0 > 0](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L437)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L408-L497


 - [ ] ID-53
[UniswapV2Adapter.getTotalValue(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L348-L372) uses a dangerous strict equality:
	- [liquidityTokens == 0](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L354)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L348-L372


## reentrancy-no-eth
Impact: Medium
Confidence: Medium
 - [ ] ID-54
Reentrancy in [VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultShares.sol#L113-L141):
	External calls:
	- [adapter.divest(IERC20(asset()),divestAmounts[i])](.contracts/protocol/VaultShares.sol#L127)
	- [IERC20(asset()).approve(address(adapter_scope_1),amount)](.contracts/protocol/VaultShares.sol#L138)
	- [adapter_scope_1.invest(IERC20(asset()),amount)](.contracts/protocol/VaultShares.sol#L139)
	State variables written after the call(s):
	- [s_allocations[adapterIndex].allocation = investAllocations[i_scope_0]](.contracts/protocol/VaultShares.sol#L135)
	[VaultShares.s_allocations](.contracts/protocol/VaultShares.sol#L46) can be used in cross function reentrancies:
	- [VaultShares._investFunds(uint256)](.contracts/protocol/VaultShares.sol#L167-L189)
	- [VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultShares.sol#L113-L141)
	- [VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L340-L353)
	- [VaultShares.updateHoldingAllocation(IVaultShares.Allocation[])](.contracts/protocol/VaultShares.sol#L94-L104)
	- [VaultShares.withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L146-L161)

.contracts/protocol/VaultShares.sol#L113-L141


 - [ ] ID-55
Reentrancy in [VaultShares.updateHoldingAllocation(IVaultShares.Allocation[])](.contracts/protocol/VaultShares.sol#L94-L104):
	External calls:
	- [withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L96)
		- [adapter.divest(IERC20(asset()),type()(uint256).max)](.contracts/protocol/VaultShares.sol#L158)
	State variables written after the call(s):
	- [s_allocations = allocations](.contracts/protocol/VaultShares.sol#L99)
	[VaultShares.s_allocations](.contracts/protocol/VaultShares.sol#L46) can be used in cross function reentrancies:
	- [VaultShares._investFunds(uint256)](.contracts/protocol/VaultShares.sol#L167-L189)
	- [VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultShares.sol#L113-L141)
	- [VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L340-L353)
	- [VaultShares.updateHoldingAllocation(IVaultShares.Allocation[])](.contracts/protocol/VaultShares.sol#L94-L104)
	- [VaultShares.withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L146-L161)

.contracts/protocol/VaultShares.sol#L94-L104


 - [ ] ID-56
Reentrancy in [VaultSharesETH.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultSharesETH.sol#L121-L149):
	External calls:
	- [adapter.divest(IERC20(asset()),divestAmounts[i])](.contracts/protocol/VaultSharesETH.sol#L135)
	- [IERC20(asset()).approve(address(adapter_scope_1),amount)](.contracts/protocol/VaultSharesETH.sol#L146)
	- [adapter_scope_1.invest(IERC20(asset()),amount)](.contracts/protocol/VaultSharesETH.sol#L147)
	State variables written after the call(s):
	- [s_allocations[adapterIndex].allocation = investAllocations[i_scope_0]](.contracts/protocol/VaultSharesETH.sol#L143)
	[VaultSharesETH.s_allocations](.contracts/protocol/VaultSharesETH.sol#L36) can be used in cross function reentrancies:
	- [VaultSharesETH._investFunds(uint256)](.contracts/protocol/VaultSharesETH.sol#L336-L358)
	- [VaultSharesETH.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultSharesETH.sol#L121-L149)
	- [VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422)
	- [VaultSharesETH.updateHoldingAllocation(IVaultShares.Allocation[])](.contracts/protocol/VaultSharesETH.sol#L106-L116)
	- [VaultSharesETH.withdrawAllInvestments()](.contracts/protocol/VaultSharesETH.sol#L154-L169)

.contracts/protocol/VaultSharesETH.sol#L121-L149


 - [ ] ID-57
Reentrancy in [VaultSharesETH.withdrawETH(uint256,address,address)](.contracts/protocol/VaultSharesETH.sol#L290-L326):
	External calls:
	- [_divestFunds(assets)](.contracts/protocol/VaultSharesETH.sol#L302)
		- [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultSharesETH.sol#L379)
	State variables written after the call(s):
	- [_burn(ownerAddr,shares)](.contracts/protocol/VaultSharesETH.sol#L305)
		- [_balances[from] = fromBalance - value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L187)
		- [_balances[to] += value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L199)
	[ERC20._balances](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L30) can be used in cross function reentrancies:
	- [ERC20._update(address,address,uint256)](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L176-L204)
	- [ERC20.balanceOf(address)](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L87-L89)
	- [_burn(ownerAddr,shares)](.contracts/protocol/VaultSharesETH.sol#L305)
		- [_totalSupply += value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L179)
		- [_totalSupply -= value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L194)
	[ERC20._totalSupply](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L34) can be used in cross function reentrancies:
	- [ERC20._update(address,address,uint256)](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L176-L204)
	- [ERC20.totalSupply()](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L82-L84)

.contracts/protocol/VaultSharesETH.sol#L290-L326


 - [ ] ID-58
Reentrancy in [UniswapV3Adapter._investWithBalances(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L408-L497):
	External calls:
	- [_swapToken(IERC20(token1Addr),IERC20(token0Addr),config.feeTier,amountToSwap,config.slippageTolerance)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L436)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L251-L252)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L270)
	- [_swapToken(IERC20(token0Addr),IERC20(token1Addr),config.feeTier,amountToSwap_scope_0,config.slippageTolerance)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L447)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L251-L252)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L270)
	- [(tokenId,liquidityMinted,amount0,amount1) = i_positionManager.mint(mintParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L476)
	State variables written after the call(s):
	- [s_tokenConfigs[token].tokenId = tokenId](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L477)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L157-L197)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L135-L147)
	- [UniswapV3Adapter._divest(IERC20,uint256,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611)
	- [UniswapV3Adapter._investWithBalances(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L408-L497)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L396-L399)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L89-L128)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L408-L497


 - [ ] ID-59
Reentrancy in [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L157-L197):
	External calls:
	- [_divest(token,type()(uint256).max,config)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L173)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L251-L252)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L270)
		- [(amount0,amount1) = i_positionManager.decreaseLiquidity(decreaseParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L642)
		- [i_positionManager.collect(collectParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L651)
		- [i_positionManager.burn(tokenId)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L590)
	- [(liquidityMinted,amount0,amount1) = _investWithBalances(token)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L192)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L251-L252)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L270)
		- [(tokenId,liquidityMinted,amount0,amount1) = i_positionManager.mint(mintParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L476)
		- [(liquidityMinted,amount0,amount1) = i_positionManager.increaseLiquidity(increaseParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L495)
	State variables written after the call(s):
	- [(liquidityMinted,amount0,amount1) = _investWithBalances(token)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L192)
		- [s_tokenConfigs[token].tokenId = tokenId](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L477)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L157-L197)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L135-L147)
	- [UniswapV3Adapter._divest(IERC20,uint256,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611)
	- [UniswapV3Adapter._investWithBalances(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L408-L497)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L396-L399)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L89-L128)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L157-L197


 - [ ] ID-60
Reentrancy in [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L157-L197):
	External calls:
	- [_divest(token,type()(uint256).max,config)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L173)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L251-L252)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L270)
		- [(amount0,amount1) = i_positionManager.decreaseLiquidity(decreaseParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L642)
		- [i_positionManager.collect(collectParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L651)
		- [i_positionManager.burn(tokenId)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L590)
	State variables written after the call(s):
	- [s_tokenConfigs[token].counterPartyToken = counterPartyToken](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L182)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L157-L197)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L135-L147)
	- [UniswapV3Adapter._divest(IERC20,uint256,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611)
	- [UniswapV3Adapter._investWithBalances(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L408-L497)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L396-L399)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L89-L128)
	- [s_tokenConfigs[token].feeTier = feeTier](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L183)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L157-L197)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L135-L147)
	- [UniswapV3Adapter._divest(IERC20,uint256,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611)
	- [UniswapV3Adapter._investWithBalances(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L408-L497)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L396-L399)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L89-L128)
	- [s_tokenConfigs[token].tickLower = tickLower](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L184)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L157-L197)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L135-L147)
	- [UniswapV3Adapter._divest(IERC20,uint256,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611)
	- [UniswapV3Adapter._investWithBalances(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L408-L497)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L396-L399)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L89-L128)
	- [s_tokenConfigs[token].tickUpper = tickUpper](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L185)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L157-L197)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L135-L147)
	- [UniswapV3Adapter._divest(IERC20,uint256,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611)
	- [UniswapV3Adapter._investWithBalances(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L408-L497)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L396-L399)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L89-L128)
	- [s_tokenConfigs[token].pool = pool](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L186)
	[UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59) can be used in cross function reentrancies:
	- [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L157-L197)
	- [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L135-L147)
	- [UniswapV3Adapter._divest(IERC20,uint256,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611)
	- [UniswapV3Adapter._investWithBalances(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L408-L497)
	- [UniswapV3Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L396-L399)
	- [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59)
	- [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L89-L128)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L157-L197


 - [ ] ID-61
Reentrancy in [VaultShares.redeem(uint256,address,address)](.contracts/protocol/VaultShares.sol#L289-L306):
	External calls:
	- [_divestFunds(assets)](.contracts/protocol/VaultShares.sol#L303)
		- [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultShares.sol#L210)
	State variables written after the call(s):
	- [_withdraw(_msgSender(),receiver,ownerAddr,assets,shares)](.contracts/protocol/VaultShares.sol#L305)
		- [_balances[from] = fromBalance - value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L187)
		- [_balances[to] += value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L199)
	[ERC20._balances](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L30) can be used in cross function reentrancies:
	- [ERC20._update(address,address,uint256)](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L176-L204)
	- [ERC20.balanceOf(address)](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L87-L89)
	- [_withdraw(_msgSender(),receiver,ownerAddr,assets,shares)](.contracts/protocol/VaultShares.sol#L305)
		- [_totalSupply += value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L179)
		- [_totalSupply -= value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L194)
	[ERC20._totalSupply](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L34) can be used in cross function reentrancies:
	- [ERC20._update(address,address,uint256)](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L176-L204)
	- [ERC20.totalSupply()](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L82-L84)

.contracts/protocol/VaultShares.sol#L289-L306


 - [ ] ID-62
Reentrancy in [VaultSharesETH.redeemETH(uint256,address,address)](.contracts/protocol/VaultSharesETH.sol#L253-L284):
	External calls:
	- [_divestFunds(assets)](.contracts/protocol/VaultSharesETH.sol#L266)
		- [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultSharesETH.sol#L379)
	State variables written after the call(s):
	- [_burn(ownerAddr,shares)](.contracts/protocol/VaultSharesETH.sol#L269)
		- [_balances[from] = fromBalance - value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L187)
		- [_balances[to] += value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L199)
	[ERC20._balances](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L30) can be used in cross function reentrancies:
	- [ERC20._update(address,address,uint256)](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L176-L204)
	- [ERC20.balanceOf(address)](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L87-L89)
	- [_burn(ownerAddr,shares)](.contracts/protocol/VaultSharesETH.sol#L269)
		- [_totalSupply += value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L179)
		- [_totalSupply -= value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L194)
	[ERC20._totalSupply](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L34) can be used in cross function reentrancies:
	- [ERC20._update(address,address,uint256)](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L176-L204)
	- [ERC20.totalSupply()](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L82-L84)

.contracts/protocol/VaultSharesETH.sol#L253-L284


 - [ ] ID-63
Reentrancy in [VaultSharesETH.updateHoldingAllocation(IVaultShares.Allocation[])](.contracts/protocol/VaultSharesETH.sol#L106-L116):
	External calls:
	- [withdrawAllInvestments()](.contracts/protocol/VaultSharesETH.sol#L108)
		- [adapter.divest(IERC20(asset()),type()(uint256).max)](.contracts/protocol/VaultSharesETH.sol#L166)
	State variables written after the call(s):
	- [s_allocations = allocations](.contracts/protocol/VaultSharesETH.sol#L111)
	[VaultSharesETH.s_allocations](.contracts/protocol/VaultSharesETH.sol#L36) can be used in cross function reentrancies:
	- [VaultSharesETH._investFunds(uint256)](.contracts/protocol/VaultSharesETH.sol#L336-L358)
	- [VaultSharesETH.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultSharesETH.sol#L121-L149)
	- [VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422)
	- [VaultSharesETH.updateHoldingAllocation(IVaultShares.Allocation[])](.contracts/protocol/VaultSharesETH.sol#L106-L116)
	- [VaultSharesETH.withdrawAllInvestments()](.contracts/protocol/VaultSharesETH.sol#L154-L169)

.contracts/protocol/VaultSharesETH.sol#L106-L116


 - [ ] ID-64
Reentrancy in [UniswapV2Adapter.updateTokenConfigAndReinvest(IERC20,IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L102-L149):
	External calls:
	- [_divest(token,currentAssetValue,config)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L137)
		- [amounts = i_uniswapRouter.swapExactTokensForTokens({amountIn:amountIn,amountOutMin:minOut,path:path,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L336-L342)
		- [(actualTokenAmount,counterPartyAmount) = i_uniswapRouter.removeLiquidity({tokenA:address(asset),tokenB:address(config.counterPartyToken),liquidity:liquidityToRemove,amountAMin:amountAMin,amountBMin:amountBMin,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L297-L305)
	State variables written after the call(s):
	- [s_tokenConfigs[token].counterPartyToken = counterPartyToken](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L141)
	[UniswapV2Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L33) can be used in cross function reentrancies:
	- [UniswapV2Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L82-L95)
	- [UniswapV2Adapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L175-L212)
	- [UniswapV2Adapter.getTokenConfig(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L383-L386)
	- [UniswapV2Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L33)
	- [UniswapV2Adapter.setTokenConfig(IERC20,uint256,IERC20,address)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L52-L75)
	- [UniswapV2Adapter.updateTokenConfigAndReinvest(IERC20,IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L102-L149)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L102-L149


 - [ ] ID-65
Reentrancy in [VaultShares.withdraw(uint256,address,address)](.contracts/protocol/VaultShares.sol#L312-L328):
	External calls:
	- [_divestFunds(assets)](.contracts/protocol/VaultShares.sol#L325)
		- [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultShares.sol#L210)
	State variables written after the call(s):
	- [_withdraw(_msgSender(),receiver,ownerAddr,assets,shares)](.contracts/protocol/VaultShares.sol#L327)
		- [_balances[from] = fromBalance - value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L187)
		- [_balances[to] += value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L199)
	[ERC20._balances](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L30) can be used in cross function reentrancies:
	- [ERC20._update(address,address,uint256)](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L176-L204)
	- [ERC20.balanceOf(address)](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L87-L89)
	- [_withdraw(_msgSender(),receiver,ownerAddr,assets,shares)](.contracts/protocol/VaultShares.sol#L327)
		- [_totalSupply += value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L179)
		- [_totalSupply -= value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L194)
	[ERC20._totalSupply](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L34) can be used in cross function reentrancies:
	- [ERC20._update(address,address,uint256)](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L176-L204)
	- [ERC20.totalSupply()](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L82-L84)

.contracts/protocol/VaultShares.sol#L312-L328


## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-66
[UniswapV3Adapter._divest(IERC20,uint256,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611) ignores return value by [(sqrtPriceX96,None,None,None,None,None,None) = config.pool.slot0()](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L542)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611


 - [ ] ID-67
[UniswapV2Adapter._divest(IERC20,uint256,UniswapV2Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323) ignores return value by [(reserve0,reserve1,None) = pair.getReserves()](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L255)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323


 - [ ] ID-68
[VaultSharesETH.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultSharesETH.sol#L121-L149) ignores return value by [IERC20(asset()).approve(address(adapter_scope_1),amount)](.contracts/protocol/VaultSharesETH.sol#L146)

.contracts/protocol/VaultSharesETH.sol#L121-L149


 - [ ] ID-69
[UniswapV3Adapter._removeLiquidityAndCollectTokens(UniswapV3Adapter.TokenConfig,uint256,uint128)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L621-L652) ignores return value by [i_positionManager.collect(collectParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L651)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L621-L652


 - [ ] ID-70
[VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultShares.sol#L113-L141) ignores return value by [adapter_scope_1.invest(IERC20(asset()),amount)](.contracts/protocol/VaultShares.sol#L139)

.contracts/protocol/VaultShares.sol#L113-L141


 - [ ] ID-71
[UniswapV3Adapter.getTotalValue(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L279-L347) ignores return value by [(token0,token1,liquidity,tokensOwed0,tokensOwed1) = i_positionManager.positions(tokenId)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L289-L346)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L279-L347


 - [ ] ID-72
[UniswapV3Adapter._investWithBalances(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L408-L497) ignores return value by [(sqrtPriceX96,None,None,None,None,None,None) = config.pool.slot0()](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L417)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L408-L497


 - [ ] ID-73
[UniswapV2Adapter.updateTokenConfigAndReinvest(IERC20,IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L102-L149) ignores return value by [(reserve0,reserve1,None) = pair.getReserves()](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L125)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L102-L149


 - [ ] ID-74
[UniswapV2Adapter.getTotalValue(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L348-L372) ignores return value by [(reserve0,reserve1,None) = pair.getReserves()](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L357)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L348-L372


 - [ ] ID-75
[VaultShares._divestFunds(uint256)](.contracts/protocol/VaultShares.sol#L195-L213) ignores return value by [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultShares.sol#L210)

.contracts/protocol/VaultShares.sol#L195-L213


 - [ ] ID-76
[VaultShares._investFunds(uint256)](.contracts/protocol/VaultShares.sol#L167-L189) ignores return value by [adapter.invest(IERC20(asset()),amountToInvest)](.contracts/protocol/VaultShares.sol#L186)

.contracts/protocol/VaultShares.sol#L167-L189


 - [ ] ID-77
[UniswapV3Adapter._divest(IERC20,uint256,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611) ignores return value by [(currentLiquidity) = i_positionManager.positions(tokenId)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L514-L596)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611


 - [ ] ID-78
[UniswapV3Adapter.getTotalValue(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L279-L347) ignores return value by [(sqrtPriceX96,None,None,None,None,None,None) = config.pool.slot0()](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L313)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L279-L347


 - [ ] ID-79
[VaultSharesETH.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultSharesETH.sol#L121-L149) ignores return value by [adapter_scope_1.invest(IERC20(asset()),amount)](.contracts/protocol/VaultSharesETH.sol#L147)

.contracts/protocol/VaultSharesETH.sol#L121-L149


 - [ ] ID-80
[VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultShares.sol#L113-L141) ignores return value by [adapter.divest(IERC20(asset()),divestAmounts[i])](.contracts/protocol/VaultShares.sol#L127)

.contracts/protocol/VaultShares.sol#L113-L141


 - [ ] ID-81
[VaultShares.withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L146-L161) ignores return value by [adapter.divest(IERC20(asset()),type()(uint256).max)](.contracts/protocol/VaultShares.sol#L158)

.contracts/protocol/VaultShares.sol#L146-L161


 - [ ] ID-82
[VaultSharesETH._investFunds(uint256)](.contracts/protocol/VaultSharesETH.sol#L336-L358) ignores return value by [adapter.invest(IERC20(asset()),amountToInvest)](.contracts/protocol/VaultSharesETH.sol#L355)

.contracts/protocol/VaultSharesETH.sol#L336-L358


 - [ ] ID-83
[VaultSharesETH.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultSharesETH.sol#L121-L149) ignores return value by [adapter.divest(IERC20(asset()),divestAmounts[i])](.contracts/protocol/VaultSharesETH.sol#L135)

.contracts/protocol/VaultSharesETH.sol#L121-L149


 - [ ] ID-84
[VaultSharesETH._divestFunds(uint256)](.contracts/protocol/VaultSharesETH.sol#L364-L382) ignores return value by [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultSharesETH.sol#L379)

.contracts/protocol/VaultSharesETH.sol#L364-L382


 - [ ] ID-85
[UniswapV3Adapter._getPositionAmounts(UniswapV3Adapter.TokenConfig,uint128)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L356-L370) ignores return value by [LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96,sqrtRatioAX96,sqrtRatioBX96,liquidity)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L369)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L356-L370


 - [ ] ID-86
[UniswapV3Adapter._getPositionAmounts(UniswapV3Adapter.TokenConfig,uint128)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L356-L370) ignores return value by [(sqrtPriceX96,None,None,None,None,None,None) = config.pool.slot0()](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L362)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L356-L370


 - [ ] ID-87
[VaultSharesETH.withdrawAllInvestments()](.contracts/protocol/VaultSharesETH.sol#L154-L169) ignores return value by [adapter.divest(IERC20(asset()),type()(uint256).max)](.contracts/protocol/VaultSharesETH.sol#L166)

.contracts/protocol/VaultSharesETH.sol#L154-L169


 - [ ] ID-88
[VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultShares.sol#L113-L141) ignores return value by [IERC20(asset()).approve(address(adapter_scope_1),amount)](.contracts/protocol/VaultShares.sol#L138)

.contracts/protocol/VaultShares.sol#L113-L141


 - [ ] ID-89
[UniswapV3Adapter.getTotalValue(IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L279-L347) ignores return value by [(sqrtPriceX96_scope_0,None,None,None,None,None,None) = config.pool.slot0()](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L328)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L279-L347


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-90
[VaultSharesETH.redeemETH(uint256,address,address).receiver](.contracts/protocol/VaultSharesETH.sol#L253) lacks a zero-check on :
		- [(success,None) = receiver.call{value: assets}()](.contracts/protocol/VaultSharesETH.sol#L280)

.contracts/protocol/VaultSharesETH.sol#L253


 - [ ] ID-91
[AIAgentVaultManager.constructor(address).weth](.contracts/protocol/AIAgentVaultManager.sol#L51) lacks a zero-check on :
		- [i_WETH = weth](.contracts/protocol/AIAgentVaultManager.sol#L52)

.contracts/protocol/AIAgentVaultManager.sol#L51


## calls-loop
Impact: Low
Confidence: Medium
 - [ ] ID-92
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L340-L353) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L348)
	Calls stack containing the loop:
		ERC4626.previewRedeem(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L340-L353


 - [ ] ID-93
[VaultSharesETH.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultSharesETH.sol#L121-L149) has external calls inside a loop: [IERC20(asset()).approve(address(adapter_scope_1),amount)](.contracts/protocol/VaultSharesETH.sol#L146)

.contracts/protocol/VaultSharesETH.sol#L121-L149


 - [ ] ID-94
[VaultShares.withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L146-L161) has external calls inside a loop: [adapter.divest(IERC20(asset()),type()(uint256).max)](.contracts/protocol/VaultShares.sol#L158)
	Calls stack containing the loop:
		VaultShares.updateHoldingAllocation(IVaultShares.Allocation[])

.contracts/protocol/VaultShares.sol#L146-L161


 - [ ] ID-95
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)
	Calls stack containing the loop:
		VaultSharesETH.redeemETH(uint256,address,address)
		ERC4626.previewRedeem(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-96
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L340-L353) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L348)
	Calls stack containing the loop:
		ERC4626.convertToShares(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L340-L353


 - [ ] ID-97
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)
	Calls stack containing the loop:
		ERC4626.convertToAssets(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-98
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L340-L353) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L348)
	Calls stack containing the loop:
		VaultShares.mint(uint256,address)
		ERC4626.previewMint(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L340-L353


 - [ ] ID-99
[VaultShares._investFunds(uint256)](.contracts/protocol/VaultShares.sol#L167-L189) has external calls inside a loop: [adapter.invest(IERC20(asset()),amountToInvest)](.contracts/protocol/VaultShares.sol#L186)
	Calls stack containing the loop:
		VaultShares.deposit(uint256,address)

.contracts/protocol/VaultShares.sol#L167-L189


 - [ ] ID-100
[VaultSharesETH.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultSharesETH.sol#L121-L149) has external calls inside a loop: [adapter_scope_1.invest(IERC20(asset()),amount)](.contracts/protocol/VaultSharesETH.sol#L147)

.contracts/protocol/VaultSharesETH.sol#L121-L149


 - [ ] ID-101
[VaultShares.withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L146-L161) has external calls inside a loop: [valueInAdapter = adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L153)

.contracts/protocol/VaultShares.sol#L146-L161


 - [ ] ID-102
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)
	Calls stack containing the loop:
		ERC4626.deposit(uint256,address)
		ERC4626.previewDeposit(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-103
[VaultSharesETH.withdrawAllInvestments()](.contracts/protocol/VaultSharesETH.sol#L154-L169) has external calls inside a loop: [valueInAdapter = adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L161)

.contracts/protocol/VaultSharesETH.sol#L154-L169


 - [ ] ID-104
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)
	Calls stack containing the loop:
		VaultSharesETH.depositETH(address)
		ERC4626.previewDeposit(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-105
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)
	Calls stack containing the loop:
		ERC4626.withdraw(uint256,address,address)
		ERC4626.maxWithdraw(address)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-106
[VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultShares.sol#L113-L141) has external calls inside a loop: [IERC20(asset()).approve(address(adapter_scope_1),amount)](.contracts/protocol/VaultShares.sol#L138)

.contracts/protocol/VaultShares.sol#L113-L141


 - [ ] ID-107
[VaultSharesETH.withdrawAllInvestments()](.contracts/protocol/VaultSharesETH.sol#L154-L169) has external calls inside a loop: [adapter.divest(IERC20(asset()),type()(uint256).max)](.contracts/protocol/VaultSharesETH.sol#L166)

.contracts/protocol/VaultSharesETH.sol#L154-L169


 - [ ] ID-108
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)
	Calls stack containing the loop:
		ERC4626.maxWithdraw(address)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-109
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)
	Calls stack containing the loop:
		ERC4626.redeem(uint256,address,address)
		ERC4626.previewRedeem(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-110
[VaultShares.withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L146-L161) has external calls inside a loop: [valueInAdapter = adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L153)
	Calls stack containing the loop:
		VaultShares.updateHoldingAllocation(IVaultShares.Allocation[])

.contracts/protocol/VaultShares.sol#L146-L161


 - [ ] ID-111
[VaultSharesETH.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultSharesETH.sol#L121-L149) has external calls inside a loop: [adapter.divest(IERC20(asset()),divestAmounts[i])](.contracts/protocol/VaultSharesETH.sol#L135)

.contracts/protocol/VaultSharesETH.sol#L121-L149


 - [ ] ID-112
[VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultShares.sol#L113-L141) has external calls inside a loop: [adapter.divest(IERC20(asset()),divestAmounts[i])](.contracts/protocol/VaultShares.sol#L127)

.contracts/protocol/VaultShares.sol#L113-L141


 - [ ] ID-113
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L340-L353) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L348)
	Calls stack containing the loop:
		ERC4626.previewWithdraw(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L340-L353


 - [ ] ID-114
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L340-L353) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L348)
	Calls stack containing the loop:
		VaultShares.deposit(uint256,address)
		ERC4626.previewDeposit(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L340-L353


 - [ ] ID-115
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L340-L353) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L348)
	Calls stack containing the loop:
		VaultShares.withdraw(uint256,address,address)
		ERC4626.previewWithdraw(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L340-L353


 - [ ] ID-116
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L340-L353) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L348)
	Calls stack containing the loop:
		ERC4626.previewDeposit(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L340-L353


 - [ ] ID-117
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)
	Calls stack containing the loop:
		ERC4626.previewDeposit(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-118
[VaultShares._investFunds(uint256)](.contracts/protocol/VaultShares.sol#L167-L189) has external calls inside a loop: [adapter.invest(IERC20(asset()),amountToInvest)](.contracts/protocol/VaultShares.sol#L186)
	Calls stack containing the loop:
		VaultShares.updateHoldingAllocation(IVaultShares.Allocation[])

.contracts/protocol/VaultShares.sol#L167-L189


 - [ ] ID-119
[VaultSharesETH.withdrawAllInvestments()](.contracts/protocol/VaultSharesETH.sol#L154-L169) has external calls inside a loop: [adapter.divest(IERC20(asset()),type()(uint256).max)](.contracts/protocol/VaultSharesETH.sol#L166)
	Calls stack containing the loop:
		VaultSharesETH.updateHoldingAllocation(IVaultShares.Allocation[])

.contracts/protocol/VaultSharesETH.sol#L154-L169


 - [ ] ID-120
[VaultSharesETH.withdrawAllInvestments()](.contracts/protocol/VaultSharesETH.sol#L154-L169) has external calls inside a loop: [valueInAdapter = adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L161)
	Calls stack containing the loop:
		VaultSharesETH.updateHoldingAllocation(IVaultShares.Allocation[])

.contracts/protocol/VaultSharesETH.sol#L154-L169


 - [ ] ID-121
[VaultSharesETH._divestFunds(uint256)](.contracts/protocol/VaultSharesETH.sol#L364-L382) has external calls inside a loop: [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultSharesETH.sol#L379)
	Calls stack containing the loop:
		VaultSharesETH.redeemETH(uint256,address,address)

.contracts/protocol/VaultSharesETH.sol#L364-L382


 - [ ] ID-122
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)
	Calls stack containing the loop:
		VaultSharesETH.withdrawETH(uint256,address,address)
		ERC4626.previewWithdraw(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-123
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L340-L353) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L348)
	Calls stack containing the loop:
		ERC4626.maxWithdraw(address)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L340-L353


 - [ ] ID-124
[VaultShares._divestFunds(uint256)](.contracts/protocol/VaultShares.sol#L195-L213) has external calls inside a loop: [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultShares.sol#L210)
	Calls stack containing the loop:
		VaultShares.redeem(uint256,address,address)

.contracts/protocol/VaultShares.sol#L195-L213


 - [ ] ID-125
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L340-L353) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L348)

.contracts/protocol/VaultShares.sol#L340-L353


 - [ ] ID-126
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)
	Calls stack containing the loop:
		VaultSharesETH.mintETH(uint256,address)
		ERC4626.previewMint(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-127
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)
	Calls stack containing the loop:
		ERC4626.previewMint(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-128
[VaultSharesETH._investFunds(uint256)](.contracts/protocol/VaultSharesETH.sol#L336-L358) has external calls inside a loop: [adapter.invest(IERC20(asset()),amountToInvest)](.contracts/protocol/VaultSharesETH.sol#L355)
	Calls stack containing the loop:
		VaultSharesETH.mintETH(uint256,address)

.contracts/protocol/VaultSharesETH.sol#L336-L358


 - [ ] ID-129
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)
	Calls stack containing the loop:
		ERC4626.mint(uint256,address)
		ERC4626.previewMint(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-130
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L340-L353) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L348)
	Calls stack containing the loop:
		ERC4626.convertToAssets(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L340-L353


 - [ ] ID-131
[VaultSharesETH._investFunds(uint256)](.contracts/protocol/VaultSharesETH.sol#L336-L358) has external calls inside a loop: [adapter.invest(IERC20(asset()),amountToInvest)](.contracts/protocol/VaultSharesETH.sol#L355)
	Calls stack containing the loop:
		VaultSharesETH.depositETH(address)

.contracts/protocol/VaultSharesETH.sol#L336-L358


 - [ ] ID-132
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L340-L353) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L348)
	Calls stack containing the loop:
		VaultShares.redeem(uint256,address,address)
		ERC4626.previewRedeem(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L340-L353


 - [ ] ID-133
[VaultSharesETH._investFunds(uint256)](.contracts/protocol/VaultSharesETH.sol#L336-L358) has external calls inside a loop: [adapter.invest(IERC20(asset()),amountToInvest)](.contracts/protocol/VaultSharesETH.sol#L355)
	Calls stack containing the loop:
		VaultSharesETH.updateHoldingAllocation(IVaultShares.Allocation[])

.contracts/protocol/VaultSharesETH.sol#L336-L358


 - [ ] ID-134
[VaultShares._divestFunds(uint256)](.contracts/protocol/VaultShares.sol#L195-L213) has external calls inside a loop: [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultShares.sol#L210)
	Calls stack containing the loop:
		VaultShares.withdraw(uint256,address,address)

.contracts/protocol/VaultShares.sol#L195-L213


 - [ ] ID-135
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)
	Calls stack containing the loop:
		ERC4626.previewWithdraw(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-136
[AIAgentVaultManager.executeBatch(uint256[],uint256[],bytes[])](.contracts/protocol/AIAgentVaultManager.sol#L264-L299) has external calls inside a loop: [(success,result) = target.call{value: values[i]}(data[i])](.contracts/protocol/AIAgentVaultManager.sol#L291)

.contracts/protocol/AIAgentVaultManager.sol#L264-L299


 - [ ] ID-137
[VaultShares._investFunds(uint256)](.contracts/protocol/VaultShares.sol#L167-L189) has external calls inside a loop: [adapter.invest(IERC20(asset()),amountToInvest)](.contracts/protocol/VaultShares.sol#L186)
	Calls stack containing the loop:
		VaultShares.mint(uint256,address)

.contracts/protocol/VaultShares.sol#L167-L189


 - [ ] ID-138
[VaultShares.withdrawAllInvestments()](.contracts/protocol/VaultShares.sol#L146-L161) has external calls inside a loop: [adapter.divest(IERC20(asset()),type()(uint256).max)](.contracts/protocol/VaultShares.sol#L158)

.contracts/protocol/VaultShares.sol#L146-L161


 - [ ] ID-139
[VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/VaultShares.sol#L113-L141) has external calls inside a loop: [adapter_scope_1.invest(IERC20(asset()),amount)](.contracts/protocol/VaultShares.sol#L139)

.contracts/protocol/VaultShares.sol#L113-L141


 - [ ] ID-140
[VaultShares.totalAssets()](.contracts/protocol/VaultShares.sol#L340-L353) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultShares.sol#L348)
	Calls stack containing the loop:
		ERC4626.previewMint(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultShares.sol#L340-L353


 - [ ] ID-141
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)
	Calls stack containing the loop:
		ERC4626.previewRedeem(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-142
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)
	Calls stack containing the loop:
		ERC4626.convertToShares(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-143
[VaultSharesETH.totalAssets()](.contracts/protocol/VaultSharesETH.sol#L409-L422) has external calls inside a loop: [assetsInAdapters += s_allocations[i].adapter.getTotalValue(IERC20(asset()))](.contracts/protocol/VaultSharesETH.sol#L417)

.contracts/protocol/VaultSharesETH.sol#L409-L422


 - [ ] ID-144
[VaultSharesETH._divestFunds(uint256)](.contracts/protocol/VaultSharesETH.sol#L364-L382) has external calls inside a loop: [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultSharesETH.sol#L379)
	Calls stack containing the loop:
		VaultSharesETH.withdrawETH(uint256,address,address)

.contracts/protocol/VaultSharesETH.sol#L364-L382


## reentrancy-benign
Impact: Low
Confidence: Medium
 - [ ] ID-145
Reentrancy in [VaultShares.redeem(uint256,address,address)](.contracts/protocol/VaultShares.sol#L289-L306):
	External calls:
	- [_divestFunds(assets)](.contracts/protocol/VaultShares.sol#L303)
		- [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultShares.sol#L210)
	State variables written after the call(s):
	- [_withdraw(_msgSender(),receiver,ownerAddr,assets,shares)](.contracts/protocol/VaultShares.sol#L305)
		- [_allowances[owner][spender] = value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L280)

.contracts/protocol/VaultShares.sol#L289-L306


 - [ ] ID-146
Reentrancy in [VaultSharesETH.redeemETH(uint256,address,address)](.contracts/protocol/VaultSharesETH.sol#L253-L284):
	External calls:
	- [_divestFunds(assets)](.contracts/protocol/VaultSharesETH.sol#L266)
		- [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultSharesETH.sol#L379)
	- [IWETH9(i_WETH).withdraw(assets)](.contracts/protocol/VaultSharesETH.sol#L275)
	State variables written after the call(s):
	- [s_ethConversionEnabled = true](.contracts/protocol/VaultSharesETH.sol#L278)

.contracts/protocol/VaultSharesETH.sol#L253-L284


 - [ ] ID-147
Reentrancy in [VaultSharesETH.withdrawETH(uint256,address,address)](.contracts/protocol/VaultSharesETH.sol#L290-L326):
	External calls:
	- [_divestFunds(assets)](.contracts/protocol/VaultSharesETH.sol#L302)
		- [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultSharesETH.sol#L379)
	State variables written after the call(s):
	- [s_ethConversionEnabled = false](.contracts/protocol/VaultSharesETH.sol#L308)

.contracts/protocol/VaultSharesETH.sol#L290-L326


 - [ ] ID-148
Reentrancy in [VaultSharesETH.redeemETH(uint256,address,address)](.contracts/protocol/VaultSharesETH.sol#L253-L284):
	External calls:
	- [_divestFunds(assets)](.contracts/protocol/VaultSharesETH.sol#L266)
		- [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultSharesETH.sol#L379)
	State variables written after the call(s):
	- [s_ethConversionEnabled = false](.contracts/protocol/VaultSharesETH.sol#L272)

.contracts/protocol/VaultSharesETH.sol#L253-L284


 - [ ] ID-149
Reentrancy in [VaultShares.withdraw(uint256,address,address)](.contracts/protocol/VaultShares.sol#L312-L328):
	External calls:
	- [_divestFunds(assets)](.contracts/protocol/VaultShares.sol#L325)
		- [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultShares.sol#L210)
	State variables written after the call(s):
	- [_withdraw(_msgSender(),receiver,ownerAddr,assets,shares)](.contracts/protocol/VaultShares.sol#L327)
		- [_allowances[owner][spender] = value](.lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L280)

.contracts/protocol/VaultShares.sol#L312-L328


 - [ ] ID-150
Reentrancy in [VaultSharesETH.withdrawETH(uint256,address,address)](.contracts/protocol/VaultSharesETH.sol#L290-L326):
	External calls:
	- [_divestFunds(assets)](.contracts/protocol/VaultSharesETH.sol#L302)
		- [adapter.divest(IERC20(asset()),amountToDivest)](.contracts/protocol/VaultSharesETH.sol#L379)
	- [IWETH9(i_WETH).withdraw(assets)](.contracts/protocol/VaultSharesETH.sol#L311)
	State variables written after the call(s):
	- [s_ethConversionEnabled = true](.contracts/protocol/VaultSharesETH.sol#L314)

.contracts/protocol/VaultSharesETH.sol#L290-L326


 - [ ] ID-151
Reentrancy in [UniswapV3Adapter._divest(IERC20,uint256,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611):
	External calls:
	- [_removeLiquidityAndCollectTokens(config,tokenId,SafeCast.toUint128(liquidityToRemove))](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L585)
		- [(amount0,amount1) = i_positionManager.decreaseLiquidity(decreaseParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L642)
		- [i_positionManager.collect(collectParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L651)
	- [i_positionManager.burn(tokenId)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L590)
	State variables written after the call(s):
	- [s_tokenConfigs[asset].tokenId = 0](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L592)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611


## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-152
Reentrancy in [UniswapV2Adapter._divest(IERC20,uint256,UniswapV2Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323):
	External calls:
	- [(actualTokenAmount,counterPartyAmount) = i_uniswapRouter.removeLiquidity({tokenA:address(asset),tokenB:address(config.counterPartyToken),liquidity:liquidityToRemove,amountAMin:amountAMin,amountBMin:amountBMin,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L297-L305)
	- [swapAmount = _swap(path,counterPartyAmount,minOut)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L317)
		- [amounts = i_uniswapRouter.swapExactTokensForTokens({amountIn:amountIn,amountOutMin:minOut,path:path,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L336-L342)
	Event emitted after the call(s):
	- [UniswapDivested(address(asset),actualTokenAmount,counterPartyAmount)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L321)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323


 - [ ] ID-153
Reentrancy in [UniswapV3Adapter.invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L205-L216):
	External calls:
	- [(liquidityMinted,amount0,amount1) = _investWithBalances(asset)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L212)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L251-L252)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L270)
		- [(tokenId,liquidityMinted,amount0,amount1) = i_positionManager.mint(mintParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L476)
		- [(liquidityMinted,amount0,amount1) = i_positionManager.increaseLiquidity(increaseParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L495)
	Event emitted after the call(s):
	- [UniswapV3Invested(address(asset),amount0,amount1,liquidityMinted)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L213)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L205-L216


 - [ ] ID-154
Reentrancy in [AIAgentVaultManager.execute(uint256,uint256,bytes)](.contracts/protocol/AIAgentVaultManager.sol#L233-L255):
	External calls:
	- [(success,result) = address(adapter).call{value: value}(data)](.contracts/protocol/AIAgentVaultManager.sol#L247)
	Event emitted after the call(s):
	- [AdapterExecuted(address(adapter),value,data,result)](.contracts/protocol/AIAgentVaultManager.sol#L253)

.contracts/protocol/AIAgentVaultManager.sol#L233-L255


 - [ ] ID-155
Reentrancy in [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L157-L197):
	External calls:
	- [_divest(token,type()(uint256).max,config)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L173)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L251-L252)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L270)
		- [(amount0,amount1) = i_positionManager.decreaseLiquidity(decreaseParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L642)
		- [i_positionManager.collect(collectParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L651)
		- [i_positionManager.burn(tokenId)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L590)
	- [(liquidityMinted,amount0,amount1) = _investWithBalances(token)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L192)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L251-L252)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L270)
		- [(tokenId,liquidityMinted,amount0,amount1) = i_positionManager.mint(mintParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L476)
		- [(liquidityMinted,amount0,amount1) = i_positionManager.increaseLiquidity(increaseParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L495)
	Event emitted after the call(s):
	- [TokenConfigUpdated(address(token))](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L196)
	- [UniswapV3Invested(address(token),amount0,amount1,liquidityMinted)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L193)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L157-L197


 - [ ] ID-156
Reentrancy in [UniswapV2Adapter.updateTokenConfigAndReinvest(IERC20,IERC20)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L102-L149):
	External calls:
	- [_divest(token,currentAssetValue,config)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L137)
		- [amounts = i_uniswapRouter.swapExactTokensForTokens({amountIn:amountIn,amountOutMin:minOut,path:path,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L336-L342)
		- [(actualTokenAmount,counterPartyAmount) = i_uniswapRouter.removeLiquidity({tokenA:address(asset),tokenB:address(config.counterPartyToken),liquidity:liquidityToRemove,amountAMin:amountAMin,amountBMin:amountBMin,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L297-L305)
	- [_invest(token,availableAssets)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L146)
		- [amounts = i_uniswapRouter.swapExactTokensForTokens({amountIn:amountIn,amountOutMin:minOut,path:path,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L336-L342)
		- [(tokenAmount,counterPartyTokenAmount,liquidity) = i_uniswapRouter.addLiquidity({tokenA:address(asset),tokenB:address(config.counterPartyToken),amountADesired:amountOfTokenToSwap,amountBDesired:actualTokenB,amountAMin:(amountOfTokenToSwap * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,amountBMin:(actualTokenB * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L199-L208)
	Event emitted after the call(s):
	- [TokenConfigUpdated(address(token))](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L148)
	- [UniswapInvested(address(asset),tokenAmount,counterPartyTokenAmount,liquidity)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L210)
		- [_invest(token,availableAssets)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L146)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L102-L149


 - [ ] ID-157
Reentrancy in [AIAgentVaultManager.executeBatch(uint256[],uint256[],bytes[])](.contracts/protocol/AIAgentVaultManager.sol#L264-L299):
	External calls:
	- [(success,result) = target.call{value: values[i]}(data[i])](.contracts/protocol/AIAgentVaultManager.sol#L291)
	Event emitted after the call(s):
	- [AdapterExecuted(target,values[i],data[i],returnData[i])](.contracts/protocol/AIAgentVaultManager.sol#L297)

.contracts/protocol/AIAgentVaultManager.sol#L264-L299


 - [ ] ID-158
Reentrancy in [AIAgentVaultManager.setVaultNotActive(IERC20)](.contracts/protocol/AIAgentVaultManager.sol#L193-L203):
	External calls:
	- [s_vault[token].setNotActive()](.contracts/protocol/AIAgentVaultManager.sol#L200)
	Event emitted after the call(s):
	- [VaultEmergencyStopped(vaultAddress)](.contracts/protocol/AIAgentVaultManager.sol#L202)

.contracts/protocol/AIAgentVaultManager.sol#L193-L203


 - [ ] ID-159
Reentrancy in [AIAgentVaultManager.updateHoldingAllocation(IERC20,uint256[],uint256[])](.contracts/protocol/AIAgentVaultManager.sol#L105-L134):
	External calls:
	- [s_vault[token].updateHoldingAllocation(allocations)](.contracts/protocol/AIAgentVaultManager.sol#L131)
	Event emitted after the call(s):
	- [AllocationUpdated(vaultAddress,allocationData)](.contracts/protocol/AIAgentVaultManager.sol#L133)

.contracts/protocol/AIAgentVaultManager.sol#L105-L134


 - [ ] ID-160
Reentrancy in [UniswapV3Adapter._divest(IERC20,uint256,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611):
	External calls:
	- [_removeLiquidityAndCollectTokens(config,tokenId,SafeCast.toUint128(liquidityToRemove))](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L585)
		- [(amount0,amount1) = i_positionManager.decreaseLiquidity(decreaseParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L642)
		- [i_positionManager.collect(collectParams)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L651)
	- [i_positionManager.burn(tokenId)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L590)
	- [_swapToken(config.counterPartyToken,asset,config.feeTier,counterPartyTokenBalance,config.slippageTolerance)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L602-L604)
		- [estimatedAmountOut = i_quoter.quoteExactInputSingle(address(tokenIn),address(tokenOut),fee,amountIn,0)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L251-L252)
		- [amountOut = i_uniswapRouter.exactInputSingle(params)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L270)
	Event emitted after the call(s):
	- [UniswapV3Divested(address(asset),assetBalance)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L609)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611


 - [ ] ID-161
Reentrancy in [AIAgentVaultManager.partialUpdateHoldingAllocation(IERC20,uint256[],uint256[],uint256[],uint256[],uint256[])](.contracts/protocol/AIAgentVaultManager.sol#L145-L173):
	External calls:
	- [s_vault[token].partialUpdateHoldingAllocation(divestAdapterIndices,divestAmounts,investAdapterIndices,investAmounts,investAllocations)](.contracts/protocol/AIAgentVaultManager.sol#L168-L170)
	Event emitted after the call(s):
	- [AllocationUpdated(vaultAddress,investAllocations)](.contracts/protocol/AIAgentVaultManager.sol#L172)

.contracts/protocol/AIAgentVaultManager.sol#L145-L173


 - [ ] ID-162
Reentrancy in [UniswapV2Adapter._invest(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L175-L212):
	External calls:
	- [actualTokenB = _swap(path,amountOfTokenToSwap,(i_uniswapRouter.getAmountsOut(amountOfTokenToSwap,path)[1] * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L185-L192)
		- [amounts = i_uniswapRouter.swapExactTokensForTokens({amountIn:amountIn,amountOutMin:minOut,path:path,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L336-L342)
	- [(tokenAmount,counterPartyTokenAmount,liquidity) = i_uniswapRouter.addLiquidity({tokenA:address(asset),tokenB:address(config.counterPartyToken),amountADesired:amountOfTokenToSwap,amountBDesired:actualTokenB,amountAMin:(amountOfTokenToSwap * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,amountBMin:(actualTokenB * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,to:address(this),deadline:block.timestamp + DEADLINE_INTERVAL})](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L199-L208)
	Event emitted after the call(s):
	- [UniswapInvested(address(asset),tokenAmount,counterPartyTokenAmount,liquidity)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L210)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L175-L212


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-163
[UniswapV2Adapter._divest(IERC20,uint256,UniswapV2Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323) uses timestamp for comparisons
	Dangerous comparisons:
	- [counterPartyAmount > 0](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L308)

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L241-L323


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-164
[WadRayMath.rayMul(uint256,uint256)](.contracts/vendor/AaveV3/WadRayMath.sol#L61-L68) uses assembly
	- [INLINE ASM](.contracts/vendor/AaveV3/WadRayMath.sol#L63-L67)

.contracts/vendor/AaveV3/WadRayMath.sol#L61-L68


 - [ ] ID-165
[Math.tryMul(uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L73-L84) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L76-L80)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L73-L84


 - [ ] ID-166
[WadRayMath.rayToWad(uint256)](.contracts/vendor/AaveV3/WadRayMath.sol#L92-L98) uses assembly
	- [INLINE ASM](.contracts/vendor/AaveV3/WadRayMath.sol#L93-L97)

.contracts/vendor/AaveV3/WadRayMath.sol#L92-L98


 - [ ] ID-167
[Math.mul512(uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L37-L46) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L41-L45)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L37-L46


 - [ ] ID-168
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


 - [ ] ID-169
[Math.add512(uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L25-L30) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L26-L29)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L25-L30


 - [ ] ID-170
[SafeCast.toUint(bool)](.lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L1157-L1161) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L1158-L1160)

.lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L1157-L1161


 - [ ] ID-171
[WadRayMath.wadDiv(uint256,uint256)](.contracts/vendor/AaveV3/WadRayMath.sol#L45-L52) uses assembly
	- [INLINE ASM](.contracts/vendor/AaveV3/WadRayMath.sol#L47-L51)

.contracts/vendor/AaveV3/WadRayMath.sol#L45-L52


 - [ ] ID-172
[FullMath.mulDiv(uint256,uint256,uint256)](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102) uses assembly
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L23-L26)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L34-L36)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L47-L49)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L51-L54)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L61-L63)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L66-L68)
	- [INLINE ASM](.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L72-L74)

.contracts/vendor/UniswapV3/core/libraries/FullMath.sol#L14-L102


 - [ ] ID-173
[SafeERC20._callOptionalReturn(IERC20,bytes)](.lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L173-L191) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L176-L186)

.lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L173-L191


 - [ ] ID-174
[WadRayMath.rayDiv(uint256,uint256)](.contracts/vendor/AaveV3/WadRayMath.sol#L77-L84) uses assembly
	- [INLINE ASM](.contracts/vendor/AaveV3/WadRayMath.sol#L79-L83)

.contracts/vendor/AaveV3/WadRayMath.sol#L77-L84


 - [ ] ID-175
[Math.log2(uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L612-L651) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L648-L650)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L612-L651


 - [ ] ID-176
[Math.mulDiv(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L227-L234)
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L240-L249)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-177
[Panic.panic(uint256)](.lib/openzeppelin-contracts/contracts/utils/Panic.sol#L50-L56) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/Panic.sol#L51-L55)

.lib/openzeppelin-contracts/contracts/utils/Panic.sol#L50-L56


 - [ ] ID-178
[WadRayMath.wadMul(uint256,uint256)](.contracts/vendor/AaveV3/WadRayMath.sol#L29-L36) uses assembly
	- [INLINE ASM](.contracts/vendor/AaveV3/WadRayMath.sol#L31-L35)

.contracts/vendor/AaveV3/WadRayMath.sol#L29-L36


 - [ ] ID-179
[Math.tryMod(uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L102-L110) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L105-L108)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L102-L110


 - [ ] ID-180
[Math.tryDiv(uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L89-L97) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L92-L95)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L89-L97


 - [ ] ID-181
[console._castToPure(function(bytes))](.lib/forge-std/src/console.sol#L25-L31) uses assembly
	- [INLINE ASM](.lib/forge-std/src/console.sol#L28-L30)

.lib/forge-std/src/console.sol#L25-L31


 - [ ] ID-182
[Math.tryModExp(uint256,uint256,uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L409-L433) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L411-L432)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L409-L433


 - [ ] ID-183
[WadRayMath.wadToRay(uint256)](.contracts/vendor/AaveV3/WadRayMath.sol#L106-L113) uses assembly
	- [INLINE ASM](.contracts/vendor/AaveV3/WadRayMath.sol#L108-L112)

.contracts/vendor/AaveV3/WadRayMath.sol#L106-L113


 - [ ] ID-184
[console._sendLogPayloadImplementation(bytes)](.lib/forge-std/src/console.sol#L8-L23) uses assembly
	- [INLINE ASM](.lib/forge-std/src/console.sol#L11-L22)

.lib/forge-std/src/console.sol#L8-L23


 - [ ] ID-185
[SafeERC20._callOptionalReturnBool(IERC20,bytes)](.lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L201-L211) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L205-L209)

.lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L201-L211


 - [ ] ID-186
[Math.tryModExp(bytes,bytes,bytes)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L449-L471) uses assembly
	- [INLINE ASM](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L461-L470)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L449-L471


## pragma
Impact: Informational
Confidence: High
 - [ ] ID-187
10 different versions of Solidity are used:
	- Version constraint ^0.8.25 is used by:
		-[^0.8.25](.contracts/abstract/AStaticUSDCData.sol#L2)
		-[^0.8.25](.contracts/abstract/AStaticUSDTData.sol#L2)
		-[^0.8.25](.contracts/interfaces/IProtocolAdapter.sol#L2)
		-[^0.8.25](.contracts/interfaces/IVaultShares.sol#L2)
		-[^0.8.25](.contracts/interfaces/IWETH9.sol#L2)
		-[^0.8.25](.contracts/protocol/AIAgentVaultManager.sol#L2)
		-[^0.8.25](.contracts/protocol/VaultShares.sol#L2)
		-[^0.8.25](.contracts/protocol/VaultSharesETH.sol#L2)
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
	- Version constraint >=0.4.22<0.9.0 is used by:
		-[>=0.4.22<0.9.0](.lib/forge-std/src/console.sol#L2)
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
 - [ ] ID-188
[UniswapV3Adapter._divest(IERC20,uint256,UniswapV3Adapter.TokenConfig)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611) has a high cyclomatic complexity (12).

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L506-L611


 - [ ] ID-189
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) has a high cyclomatic complexity (24).

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


## solc-version
Impact: Informational
Confidence: High
 - [ ] ID-190
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


 - [ ] ID-191
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


 - [ ] ID-192
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


 - [ ] ID-193
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


 - [ ] ID-194
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


 - [ ] ID-195
Version constraint >=0.4.22<0.9.0 is too complex.
It is used by:
	- [>=0.4.22<0.9.0](.lib/forge-std/src/console.sol#L2)

.lib/forge-std/src/console.sol#L2


 - [ ] ID-196
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


 - [ ] ID-197
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


 - [ ] ID-198
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
 - [ ] ID-199
Low level call in [VaultSharesETH.redeemETH(uint256,address,address)](.contracts/protocol/VaultSharesETH.sol#L253-L284):
	- [(success,None) = receiver.call{value: assets}()](.contracts/protocol/VaultSharesETH.sol#L280)

.contracts/protocol/VaultSharesETH.sol#L253-L284


 - [ ] ID-200
Low level call in [VaultSharesETH.withdrawETH(uint256,address,address)](.contracts/protocol/VaultSharesETH.sol#L290-L326):
	- [(success,None) = receiver.call{value: assets}()](.contracts/protocol/VaultSharesETH.sol#L322)

.contracts/protocol/VaultSharesETH.sol#L290-L326


 - [ ] ID-201
Low level call in [ERC4626._tryGetAssetDecimals(IERC20)](.lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L86-L97):
	- [(success,encodedDecimals) = address(asset_).staticcall(abi.encodeCall(IERC20Metadata.decimals,()))](.lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L87-L89)

.lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L86-L97


 - [ ] ID-202
Low level call in [AIAgentVaultManager.executeBatch(uint256[],uint256[],bytes[])](.contracts/protocol/AIAgentVaultManager.sol#L264-L299):
	- [(success,result) = target.call{value: values[i]}(data[i])](.contracts/protocol/AIAgentVaultManager.sol#L291)

.contracts/protocol/AIAgentVaultManager.sol#L264-L299


 - [ ] ID-203
Low level call in [AIAgentVaultManager.execute(uint256,uint256,bytes)](.contracts/protocol/AIAgentVaultManager.sol#L233-L255):
	- [(success,result) = address(adapter).call{value: value}(data)](.contracts/protocol/AIAgentVaultManager.sol#L247)

.contracts/protocol/AIAgentVaultManager.sol#L233-L255


## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-204
Variable [VaultSharesETH.i_Fee](.contracts/protocol/VaultSharesETH.sol#L30) is not in mixedCase

.contracts/protocol/VaultSharesETH.sol#L30


 - [ ] ID-205
Parameter [UniswapV3Adapter.setTokenConfig(IERC20,IERC20,uint256,uint24,int24,int24,address).VaultAddress](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L96) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L96


 - [ ] ID-206
Function [UniswapV3Adapter.UpdateTokenConfig(IERC20,IERC20,uint24,int24,int24)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L157-L197) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L157-L197


 - [ ] ID-207
Function [UniswapV3Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L135-L147) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L135-L147


 - [ ] ID-208
Variable [VaultShares.i_Fee](.contracts/protocol/VaultShares.sol#L42) is not in mixedCase

.contracts/protocol/VaultShares.sol#L42


 - [ ] ID-209
Variable [AIAgentVaultManager.i_WETH](.contracts/protocol/AIAgentVaultManager.sol#L28) is not in mixedCase

.contracts/protocol/AIAgentVaultManager.sol#L28


 - [ ] ID-210
Parameter [UniswapV2Adapter.setTokenConfig(IERC20,uint256,IERC20,address).VaultAddress](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L52) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L52


 - [ ] ID-211
Variable [AaveAdapter.i_aavePool](.contracts/protocol/investableUniverseAdapters/AaveAdapter.sol#L18) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/AaveAdapter.sol#L18


 - [ ] ID-212
Function [IUniswapV2Pair.PERMIT_TYPEHASH()](.contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L28) is not in mixedCase

.contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L28


 - [ ] ID-213
Function [IUniswapV2Pair.MINIMUM_LIQUIDITY()](.contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L47) is not in mixedCase

.contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L47


 - [ ] ID-214
Contract [console](.lib/forge-std/src/console.sol#L4-L1560) is not in CapWords

.lib/forge-std/src/console.sol#L4-L1560


 - [ ] ID-215
Function [IERC721Permit.PERMIT_TYPEHASH()](.contracts/vendor/UniswapV3/periphery/interfaces/IERC721Permit.sol#L11) is not in mixedCase

.contracts/vendor/UniswapV3/periphery/interfaces/IERC721Permit.sol#L11


 - [ ] ID-216
Function [IUniswapV2Pair.DOMAIN_SEPARATOR()](.contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L26) is not in mixedCase

.contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L26


 - [ ] ID-217
Variable [VaultSharesETH.i_WETH](.contracts/protocol/VaultSharesETH.sol#L31) is not in mixedCase

.contracts/protocol/VaultSharesETH.sol#L31


 - [ ] ID-218
Variable [UniswapV3Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L59


 - [ ] ID-219
Function [IPeripheryImmutableState.WETH9()](.contracts/vendor/UniswapV3/periphery/interfaces/IPeripheryImmutableState.sol#L11) is not in mixedCase

.contracts/vendor/UniswapV3/periphery/interfaces/IPeripheryImmutableState.sol#L11


 - [ ] ID-220
Function [IERC721Permit.DOMAIN_SEPARATOR()](.contracts/vendor/UniswapV3/periphery/interfaces/IERC721Permit.sol#L15) is not in mixedCase

.contracts/vendor/UniswapV3/periphery/interfaces/IERC721Permit.sol#L15


 - [ ] ID-221
Function [UniswapV2Adapter.UpdateTokenSlippageTolerance(IERC20,uint256)](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L82-L95) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L82-L95


 - [ ] ID-222
Function [IUniswapV2Router01.WETH()](.contracts/vendor/UniswapV2/IUniswapV2Router01.sol#L9) is not in mixedCase

.contracts/vendor/UniswapV2/IUniswapV2Router01.sol#L9


 - [ ] ID-223
Constant [AIAgentVaultManager.s_Fee](.contracts/protocol/AIAgentVaultManager.sol#L30) is not in UPPER_CASE_WITH_UNDERSCORES

.contracts/protocol/AIAgentVaultManager.sol#L30


 - [ ] ID-224
Variable [UniswapV2Adapter.s_tokenConfigs](.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L33) is not in mixedCase

.contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L33


 - [ ] ID-225
Variable [AStaticUSDCData.i_USDC](.contracts/abstract/AStaticUSDCData.sol#L9) is not in mixedCase

.contracts/abstract/AStaticUSDCData.sol#L9


## too-many-digits
Impact: Informational
Confidence: Medium
 - [ ] ID-226
[UniswapV3Adapter._calculateV3OptimalSwapAmount(uint256,uint160,uint160,uint160,bool)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L664-L741) uses literals with too many digits:
	- [amountToKeep = (totalAmount * token1Ratio) / 1000000](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L692)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L664-L741


 - [ ] ID-227
[TickMath.getSqrtRatioAtTick(int24)](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92) uses literals with too many digits:
	- [ratio = 0x100000000000000000000000000000000](.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L27)

.contracts/vendor/UniswapV3/core/libraries/TickMath.sol#L23-L92


 - [ ] ID-228
[UniswapV3Adapter._calculateV3OptimalSwapAmount(uint256,uint160,uint160,uint160,bool)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L664-L741) uses literals with too many digits:
	- [token1Ratio = (numerator * 1000000) / denominator](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L691)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L664-L741


 - [ ] ID-229
[UniswapV3Adapter._calculateV3OptimalSwapAmount(uint256,uint160,uint160,uint160,bool)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L664-L741) uses literals with too many digits:
	- [token0Ratio = (numerator_scope_0 * 1000000) / denominator_scope_1](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L723)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L664-L741


 - [ ] ID-230
[Math.log2(uint256)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L612-L651) uses literals with too many digits:
	- [r = r | byte(uint256,uint256)(x >> r,0x0000010102020202030303030303030300000000000000000000000000000000)](.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L649)

.lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L612-L651


 - [ ] ID-231
[FixedPoint96.slitherConstructorConstantVariables()](.contracts/vendor/UniswapV3/core/libraries/FixedPoint96.sol#L7-L10) uses literals with too many digits:
	- [Q96 = 0x1000000000000000000000000](.contracts/vendor/UniswapV3/core/libraries/FixedPoint96.sol#L9)

.contracts/vendor/UniswapV3/core/libraries/FixedPoint96.sol#L7-L10


 - [ ] ID-232
[UniswapV3Adapter._calculateV3OptimalSwapAmount(uint256,uint160,uint160,uint160,bool)](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L664-L741) uses literals with too many digits:
	- [amountToKeep_scope_2 = (totalAmount * token0Ratio) / 1000000](.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L724)

.contracts/protocol/investableUniverseAdapters/UniswapV3Adapter.sol#L664-L741


