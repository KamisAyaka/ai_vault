**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [incorrect-exp](#incorrect-exp) (1 results) (High)
 - [divide-before-multiply](#divide-before-multiply) (14 results) (Medium)
 - [incorrect-equality](#incorrect-equality) (1 results) (Medium)
 - [reentrancy-no-eth](#reentrancy-no-eth) (1 results) (Medium)
 - [unused-return](#unused-return) (5 results) (Medium)
 - [calls-loop](#calls-loop) (20 results) (Low)
 - [reentrancy-events](#reentrancy-events) (9 results) (Low)
 - [timestamp](#timestamp) (1 results) (Low)
 - [assembly](#assembly) (19 results) (Informational)
 - [pragma](#pragma) (1 results) (Informational)
 - [solc-version](#solc-version) (6 results) (Informational)
 - [low-level-calls](#low-level-calls) (3 results) (Informational)
 - [naming-convention](#naming-convention) (11 results) (Informational)
 - [too-many-digits](#too-many-digits) (1 results) (Informational)
## incorrect-exp
Impact: High
Confidence: Medium
 - [ ] ID-0
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) has bitwise-xor operator ^ instead of the exponentiation operator **: 
	 - [inverse = (3 * denominator) ^ 2](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L257)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


## divide-before-multiply
Impact: Medium
Confidence: Medium
 - [ ] ID-1
[UniswapAdapter.getTotalValue(IERC20)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L341-L370) performs a multiplication on the result of a division:
	- [amount1 = (uint256(reserve1) * liquidityTokens) / totalSupply](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L360)
	- [amount0 + (amount1 * reserve0) / reserve1](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L364)

contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L341-L370


 - [ ] ID-2
[UniswapAdapter.invest(IERC20,uint256)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L137-L194) performs a multiplication on the result of a division:
	- [amountOfTokenToSwap = amount / 2](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L143)
	- [(tokenAmount,counterPartyTokenAmount,liquidity) = i_uniswapRouter.addLiquidity({tokenA:address(asset),tokenB:address(config.counterPartyToken),amountADesired:amountOfTokenToSwap,amountBDesired:actualTokenB,amountAMin:(amountOfTokenToSwap * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,amountBMin:(actualTokenB * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,to:msg.sender,deadline:block.timestamp + DEADLINE_INTERVAL})](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L168-L185)

contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L137-L194


 - [ ] ID-3
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L265)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-4
[UniswapAdapter.getTotalValue(IERC20)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L341-L370) performs a multiplication on the result of a division:
	- [amount0 = (uint256(reserve0) * liquidityTokens) / totalSupply](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L359)
	- [amount1 + (amount0 * reserve1) / reserve0](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L366)

contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L341-L370


 - [ ] ID-5
[UniswapAdapter._calculateMinAmounts(IERC20,IUniswapV2Pair,uint112,uint112,uint256,uint256,uint256)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L307-L338) performs a multiplication on the result of a division:
	- [((((uint256(reserve1) * liquidityAmount) / totalSupply) * (BASIS_POINTS_DIVISOR - slippageTolerance)) / BASIS_POINTS_DIVISOR,(((uint256(reserve0) * liquidityAmount) / totalSupply) * (BASIS_POINTS_DIVISOR - slippageTolerance)) / BASIS_POINTS_DIVISOR)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L330-L337)

contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L307-L338


 - [ ] ID-6
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse = (3 * denominator) ^ 2](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L257)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-7
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [low = low / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L245)
	- [result = low * inverse](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L272)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-8
[Math.invMod(uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L315-L361) performs a multiplication on the result of a division:
	- [quotient = gcd / remainder](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L337)
	- [(gcd,remainder) = (remainder,gcd - remainder * quotient)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L339-L346)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L315-L361


 - [ ] ID-9
[UniswapAdapter._calculateMinAmounts(IERC20,IUniswapV2Pair,uint112,uint112,uint256,uint256,uint256)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L307-L338) performs a multiplication on the result of a division:
	- [((((uint256(reserve0) * liquidityAmount) / totalSupply) * (BASIS_POINTS_DIVISOR - slippageTolerance)) / BASIS_POINTS_DIVISOR,(((uint256(reserve1) * liquidityAmount) / totalSupply) * (BASIS_POINTS_DIVISOR - slippageTolerance)) / BASIS_POINTS_DIVISOR)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L320-L327)

contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L307-L338


 - [ ] ID-10
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L263)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-11
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L261)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-12
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L266)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-13
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L264)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-14
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L242)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L262)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


## incorrect-equality
Impact: Medium
Confidence: High
 - [ ] ID-15
[UniswapAdapter.getTotalValue(IERC20)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L341-L370) uses a dangerous strict equality:
	- [liquidityTokens == 0](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L352)

contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L341-L370


## reentrancy-no-eth
Impact: Medium
Confidence: Medium
 - [ ] ID-16
Reentrancy in [VaultShares.updateHoldingAllocation(IProtocolAdapter[],uint256[])](contracts/protocol/VaultShares.sol#L97-L111):
	External calls:
	- [withdrawAllInvestments()](contracts/protocol/VaultShares.sol#L102)
		- [adapter.divest(IERC20(asset()),valueInAdapter)](contracts/protocol/VaultShares.sol#L182)
	- [_investInAdapters(vaultAdapters,allocationData)](contracts/protocol/VaultShares.sol#L105)
		- [vaultAdapters[i].invest(IERC20(asset()),amountToInvest)](contracts/protocol/VaultShares.sol#L212)
	State variables written after the call(s):
	- [s_allocatedAdapters = vaultAdapters](contracts/protocol/VaultShares.sol#L108)
	[VaultShares.s_allocatedAdapters](contracts/protocol/VaultShares.sol#L45) can be used in cross function reentrancies:
	- [VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[])](contracts/protocol/VaultShares.sol#L120-L166)
	- [VaultShares.totalAssets()](contracts/protocol/VaultShares.sol#L336-L356)
	- [VaultShares.updateHoldingAllocation(IProtocolAdapter[],uint256[])](contracts/protocol/VaultShares.sol#L97-L111)
	- [VaultShares.withdrawAllInvestments()](contracts/protocol/VaultShares.sol#L171-L185)

contracts/protocol/VaultShares.sol#L97-L111


## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-17
[UniswapAdapter.getTotalValue(IERC20)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L341-L370) ignores return value by [(reserve0,reserve1,None) = pair.getReserves()](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L355)

contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L341-L370


 - [ ] ID-18
[VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[])](contracts/protocol/VaultShares.sol#L120-L166) ignores return value by [currentAdapters[divestAdapterIndices[i]].divest(IERC20(asset()),divestAmounts[i])](contracts/protocol/VaultShares.sol#L142-L145)

contracts/protocol/VaultShares.sol#L120-L166


 - [ ] ID-19
[VaultShares._investInAdapters(IProtocolAdapter[],uint256[])](contracts/protocol/VaultShares.sol#L190-L215) ignores return value by [vaultAdapters[i].invest(IERC20(asset()),amountToInvest)](contracts/protocol/VaultShares.sol#L212)

contracts/protocol/VaultShares.sol#L190-L215


 - [ ] ID-20
[UniswapAdapter.divest(IERC20,uint256)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L202-L267) ignores return value by [(reserve0,reserve1,None) = pair.getReserves()](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L218)

contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L202-L267


 - [ ] ID-21
[VaultShares.withdrawAllInvestments()](contracts/protocol/VaultShares.sol#L171-L185) ignores return value by [adapter.divest(IERC20(asset()),valueInAdapter)](contracts/protocol/VaultShares.sol#L182)

contracts/protocol/VaultShares.sol#L171-L185


## calls-loop
Impact: Low
Confidence: Medium
 - [ ] ID-22
[VaultShares.totalAssets()](contracts/protocol/VaultShares.sol#L336-L356) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](contracts/protocol/VaultShares.sol#L349-L351)
	Calls stack containing the loop:
		VaultShares.deposit(uint256,address)
		ERC4626.previewDeposit(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

contracts/protocol/VaultShares.sol#L336-L356


 - [ ] ID-23
[VaultShares._investInAdapters(IProtocolAdapter[],uint256[])](contracts/protocol/VaultShares.sol#L190-L215) has external calls inside a loop: [vaultAdapters[i].invest(IERC20(asset()),amountToInvest)](contracts/protocol/VaultShares.sol#L212)
	Calls stack containing the loop:
		VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[])

contracts/protocol/VaultShares.sol#L190-L215


 - [ ] ID-24
[VaultShares.totalAssets()](contracts/protocol/VaultShares.sol#L336-L356) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](contracts/protocol/VaultShares.sol#L349-L351)

contracts/protocol/VaultShares.sol#L336-L356


 - [ ] ID-25
[VaultShares.withdrawAllInvestments()](contracts/protocol/VaultShares.sol#L171-L185) has external calls inside a loop: [valueInAdapter = adapter.getTotalValue(IERC20(asset()))](contracts/protocol/VaultShares.sol#L178)
	Calls stack containing the loop:
		VaultShares.updateHoldingAllocation(IProtocolAdapter[],uint256[])

contracts/protocol/VaultShares.sol#L171-L185


 - [ ] ID-26
[VaultShares.totalAssets()](contracts/protocol/VaultShares.sol#L336-L356) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](contracts/protocol/VaultShares.sol#L349-L351)
	Calls stack containing the loop:
		ERC4626.previewRedeem(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

contracts/protocol/VaultShares.sol#L336-L356


 - [ ] ID-27
[AIAgentVaultManager.executeBatch(uint256[],uint256[],bytes[])](contracts/protocol/AIAgentVaultManager.sol#L260-L302) has external calls inside a loop: [(success,result) = target.call{value: values[i]}(data[i])](contracts/protocol/AIAgentVaultManager.sol#L292-L294)

contracts/protocol/AIAgentVaultManager.sol#L260-L302


 - [ ] ID-28
[VaultShares.totalAssets()](contracts/protocol/VaultShares.sol#L336-L356) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](contracts/protocol/VaultShares.sol#L349-L351)
	Calls stack containing the loop:
		ERC4626.previewWithdraw(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

contracts/protocol/VaultShares.sol#L336-L356


 - [ ] ID-29
[VaultShares.totalAssets()](contracts/protocol/VaultShares.sol#L336-L356) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](contracts/protocol/VaultShares.sol#L349-L351)
	Calls stack containing the loop:
		ERC4626.convertToShares(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

contracts/protocol/VaultShares.sol#L336-L356


 - [ ] ID-30
[VaultShares.totalAssets()](contracts/protocol/VaultShares.sol#L336-L356) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](contracts/protocol/VaultShares.sol#L349-L351)
	Calls stack containing the loop:
		VaultShares.mint(uint256,address)
		ERC4626.previewMint(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

contracts/protocol/VaultShares.sol#L336-L356


 - [ ] ID-31
[VaultShares.withdrawAllInvestments()](contracts/protocol/VaultShares.sol#L171-L185) has external calls inside a loop: [adapter.divest(IERC20(asset()),valueInAdapter)](contracts/protocol/VaultShares.sol#L182)
	Calls stack containing the loop:
		VaultShares.updateHoldingAllocation(IProtocolAdapter[],uint256[])

contracts/protocol/VaultShares.sol#L171-L185


 - [ ] ID-32
[VaultShares.totalAssets()](contracts/protocol/VaultShares.sol#L336-L356) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](contracts/protocol/VaultShares.sol#L349-L351)
	Calls stack containing the loop:
		ERC4626.maxWithdraw(address)
		ERC4626._convertToAssets(uint256,Math.Rounding)

contracts/protocol/VaultShares.sol#L336-L356


 - [ ] ID-33
[VaultShares.totalAssets()](contracts/protocol/VaultShares.sol#L336-L356) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](contracts/protocol/VaultShares.sol#L349-L351)
	Calls stack containing the loop:
		ERC4626.previewDeposit(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

contracts/protocol/VaultShares.sol#L336-L356


 - [ ] ID-34
[VaultShares.totalAssets()](contracts/protocol/VaultShares.sol#L336-L356) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](contracts/protocol/VaultShares.sol#L349-L351)
	Calls stack containing the loop:
		ERC4626.convertToAssets(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

contracts/protocol/VaultShares.sol#L336-L356


 - [ ] ID-35
[VaultShares.totalAssets()](contracts/protocol/VaultShares.sol#L336-L356) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](contracts/protocol/VaultShares.sol#L349-L351)
	Calls stack containing the loop:
		VaultShares.withdraw(uint256,address,address)
		ERC4626.previewWithdraw(uint256)
		ERC4626._convertToShares(uint256,Math.Rounding)

contracts/protocol/VaultShares.sol#L336-L356


 - [ ] ID-36
[VaultShares._investInAdapters(IProtocolAdapter[],uint256[])](contracts/protocol/VaultShares.sol#L190-L215) has external calls inside a loop: [vaultAdapters[i].invest(IERC20(asset()),amountToInvest)](contracts/protocol/VaultShares.sol#L212)
	Calls stack containing the loop:
		VaultShares.updateHoldingAllocation(IProtocolAdapter[],uint256[])

contracts/protocol/VaultShares.sol#L190-L215


 - [ ] ID-37
[VaultShares.totalAssets()](contracts/protocol/VaultShares.sol#L336-L356) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](contracts/protocol/VaultShares.sol#L349-L351)
	Calls stack containing the loop:
		ERC4626.previewMint(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

contracts/protocol/VaultShares.sol#L336-L356


 - [ ] ID-38
[VaultShares.withdrawAllInvestments()](contracts/protocol/VaultShares.sol#L171-L185) has external calls inside a loop: [valueInAdapter = adapter.getTotalValue(IERC20(asset()))](contracts/protocol/VaultShares.sol#L178)

contracts/protocol/VaultShares.sol#L171-L185


 - [ ] ID-39
[VaultShares.withdrawAllInvestments()](contracts/protocol/VaultShares.sol#L171-L185) has external calls inside a loop: [adapter.divest(IERC20(asset()),valueInAdapter)](contracts/protocol/VaultShares.sol#L182)

contracts/protocol/VaultShares.sol#L171-L185


 - [ ] ID-40
[VaultShares.totalAssets()](contracts/protocol/VaultShares.sol#L336-L356) has external calls inside a loop: [assetsInAdapters += s_allocatedAdapters[i].getTotalValue(IERC20(asset()))](contracts/protocol/VaultShares.sol#L349-L351)
	Calls stack containing the loop:
		VaultShares.redeem(uint256,address,address)
		ERC4626.previewRedeem(uint256)
		ERC4626._convertToAssets(uint256,Math.Rounding)

contracts/protocol/VaultShares.sol#L336-L356


 - [ ] ID-41
[VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[])](contracts/protocol/VaultShares.sol#L120-L166) has external calls inside a loop: [currentAdapters[divestAdapterIndices[i]].divest(IERC20(asset()),divestAmounts[i])](contracts/protocol/VaultShares.sol#L142-L145)

contracts/protocol/VaultShares.sol#L120-L166


## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-42
Reentrancy in [AIAgentVaultManager.updateHoldingAllocation(IERC20,uint256[],uint256[])](contracts/protocol/AIAgentVaultManager.sol#L92-L127):
	External calls:
	- [s_vault[token].updateHoldingAllocation(selectedAdapters,allocationData)](contracts/protocol/AIAgentVaultManager.sol#L121-L124)
	Event emitted after the call(s):
	- [AllocationUpdated(vaultAddress,allocationData)](contracts/protocol/AIAgentVaultManager.sol#L126)

contracts/protocol/AIAgentVaultManager.sol#L92-L127


 - [ ] ID-43
Reentrancy in [AIAgentVaultManager.executeBatch(uint256[],uint256[],bytes[])](contracts/protocol/AIAgentVaultManager.sol#L260-L302):
	External calls:
	- [(success,result) = target.call{value: values[i]}(data[i])](contracts/protocol/AIAgentVaultManager.sol#L292-L294)
	Event emitted after the call(s):
	- [AdapterExecuted(target,values[i],data[i],returnData[i])](contracts/protocol/AIAgentVaultManager.sol#L300)

contracts/protocol/AIAgentVaultManager.sol#L260-L302


 - [ ] ID-44
Reentrancy in [UniswapAdapter.divest(IERC20,uint256)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L202-L267):
	External calls:
	- [(tokenAmount,counterPartyAmount) = i_uniswapRouter.removeLiquidity({tokenA:address(asset),tokenB:address(config.counterPartyToken),liquidity:liquidityAmount,amountAMin:minToken,amountBMin:minCounter,to:msg.sender,deadline:block.timestamp + DEADLINE_INTERVAL})](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L233-L244)
	- [swapAmount = _swap(path,counterPartyAmount,minOut)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L261)
		- [amounts = i_uniswapRouter.swapExactTokensForTokens({amountIn:amountIn,amountOutMin:minOut,path:path,to:msg.sender,deadline:block.timestamp + DEADLINE_INTERVAL})](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L284-L292)
	Event emitted after the call(s):
	- [UniswapDivested(address(asset),tokenAmount,counterPartyAmount)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L265)

contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L202-L267


 - [ ] ID-45
Reentrancy in [AIAgentVaultManager.partialUpdateHoldingAllocation(IERC20,uint256[],uint256[],uint256[],uint256[])](contracts/protocol/AIAgentVaultManager.sol#L137-L167):
	External calls:
	- [s_vault[token].partialUpdateHoldingAllocation(divestAdapterIndices,divestAmounts,investAdapterIndices,investAllocations)](contracts/protocol/AIAgentVaultManager.sol#L159-L164)
	Event emitted after the call(s):
	- [AllocationUpdated(vaultAddress,investAllocations)](contracts/protocol/AIAgentVaultManager.sol#L166)

contracts/protocol/AIAgentVaultManager.sol#L137-L167


 - [ ] ID-46
Reentrancy in [VaultShares.partialUpdateHoldingAllocation(uint256[],uint256[],uint256[],uint256[])](contracts/protocol/VaultShares.sol#L120-L166):
	External calls:
	- [currentAdapters[divestAdapterIndices[i]].divest(IERC20(asset()),divestAmounts[i])](contracts/protocol/VaultShares.sol#L142-L145)
	- [_investInAdapters(investAdapters,investAllocations)](contracts/protocol/VaultShares.sol#L163)
		- [vaultAdapters[i].invest(IERC20(asset()),amountToInvest)](contracts/protocol/VaultShares.sol#L212)
	Event emitted after the call(s):
	- [HoldingAllocationUpdated(investAdapters,investAllocations)](contracts/protocol/VaultShares.sol#L165)

contracts/protocol/VaultShares.sol#L120-L166


 - [ ] ID-47
Reentrancy in [AIAgentVaultManager.execute(uint256,uint256,bytes)](contracts/protocol/AIAgentVaultManager.sol#L227-L251):
	External calls:
	- [(success,result) = address(adapter).call{value: value}(data)](contracts/protocol/AIAgentVaultManager.sol#L241-L243)
	Event emitted after the call(s):
	- [AdapterExecuted(address(adapter),value,data,result)](contracts/protocol/AIAgentVaultManager.sol#L249)

contracts/protocol/AIAgentVaultManager.sol#L227-L251


 - [ ] ID-48
Reentrancy in [UniswapAdapter.invest(IERC20,uint256)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L137-L194):
	External calls:
	- [actualTokenB = _swap(path,amountOfTokenToSwap,(i_uniswapRouter.getAmountsOut(amountOfTokenToSwap,path)[1] * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L151-L157)
		- [amounts = i_uniswapRouter.swapExactTokensForTokens({amountIn:amountIn,amountOutMin:minOut,path:path,to:msg.sender,deadline:block.timestamp + DEADLINE_INTERVAL})](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L284-L292)
	- [(tokenAmount,counterPartyTokenAmount,liquidity) = i_uniswapRouter.addLiquidity({tokenA:address(asset),tokenB:address(config.counterPartyToken),amountADesired:amountOfTokenToSwap,amountBDesired:actualTokenB,amountAMin:(amountOfTokenToSwap * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,amountBMin:(actualTokenB * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,to:msg.sender,deadline:block.timestamp + DEADLINE_INTERVAL})](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L168-L185)
	Event emitted after the call(s):
	- [UniswapInvested(address(asset),tokenAmount,counterPartyTokenAmount,liquidity)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L187-L192)

contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L137-L194


 - [ ] ID-49
Reentrancy in [VaultShares.updateHoldingAllocation(IProtocolAdapter[],uint256[])](contracts/protocol/VaultShares.sol#L97-L111):
	External calls:
	- [withdrawAllInvestments()](contracts/protocol/VaultShares.sol#L102)
		- [adapter.divest(IERC20(asset()),valueInAdapter)](contracts/protocol/VaultShares.sol#L182)
	- [_investInAdapters(vaultAdapters,allocationData)](contracts/protocol/VaultShares.sol#L105)
		- [vaultAdapters[i].invest(IERC20(asset()),amountToInvest)](contracts/protocol/VaultShares.sol#L212)
	Event emitted after the call(s):
	- [HoldingAllocationUpdated(vaultAdapters,allocationData)](contracts/protocol/VaultShares.sol#L110)

contracts/protocol/VaultShares.sol#L97-L111


 - [ ] ID-50
Reentrancy in [AIAgentVaultManager.setVaultNotActive(IERC20)](contracts/protocol/AIAgentVaultManager.sol#L187-L197):
	External calls:
	- [s_vault[token].setNotActive()](contracts/protocol/AIAgentVaultManager.sol#L194)
	Event emitted after the call(s):
	- [VaultEmergencyStopped(vaultAddress)](contracts/protocol/AIAgentVaultManager.sol#L196)

contracts/protocol/AIAgentVaultManager.sol#L187-L197


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-51
[UniswapAdapter.divest(IERC20,uint256)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L202-L267) uses timestamp for comparisons
	Dangerous comparisons:
	- [counterPartyAmount > 0](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L247)

contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L202-L267


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-52
[Math.tryMul(uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L73-L84) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L76-L80)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L73-L84


 - [ ] ID-53
[WadRayMath.wadDiv(uint256,uint256)](contracts/vendor/AaveV3/WadRayMath.sol#L47-L56) uses assembly
	- [INLINE ASM](contracts/vendor/AaveV3/WadRayMath.sol#L49-L55)

contracts/vendor/AaveV3/WadRayMath.sol#L47-L56


 - [ ] ID-54
[Math.mul512(uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L37-L46) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L41-L45)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L37-L46


 - [ ] ID-55
[WadRayMath.wadToRay(uint256)](contracts/vendor/AaveV3/WadRayMath.sol#L116-L125) uses assembly
	- [INLINE ASM](contracts/vendor/AaveV3/WadRayMath.sol#L118-L124)

contracts/vendor/AaveV3/WadRayMath.sol#L116-L125


 - [ ] ID-56
[Math.add512(uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L25-L30) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L26-L29)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L25-L30


 - [ ] ID-57
[SafeCast.toUint(bool)](lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L1157-L1161) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L1158-L1160)

lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L1157-L1161


 - [ ] ID-58
[SafeERC20._callOptionalReturn(IERC20,bytes)](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L173-L191) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L176-L186)

lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L173-L191


 - [ ] ID-59
[Math.log2(uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L612-L651) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L648-L650)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L612-L651


 - [ ] ID-60
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L227-L234)
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L240-L249)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L204-L275


 - [ ] ID-61
[Panic.panic(uint256)](lib/openzeppelin-contracts/contracts/utils/Panic.sol#L50-L56) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/Panic.sol#L51-L55)

lib/openzeppelin-contracts/contracts/utils/Panic.sol#L50-L56


 - [ ] ID-62
[WadRayMath.rayToWad(uint256)](contracts/vendor/AaveV3/WadRayMath.sol#L100-L108) uses assembly
	- [INLINE ASM](contracts/vendor/AaveV3/WadRayMath.sol#L101-L107)

contracts/vendor/AaveV3/WadRayMath.sol#L100-L108


 - [ ] ID-63
[Math.tryMod(uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L102-L110) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L105-L108)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L102-L110


 - [ ] ID-64
[Math.tryDiv(uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L89-L97) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L92-L95)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L89-L97


 - [ ] ID-65
[Math.tryModExp(uint256,uint256,uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L409-L433) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L411-L432)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L409-L433


 - [ ] ID-66
[WadRayMath.rayDiv(uint256,uint256)](contracts/vendor/AaveV3/WadRayMath.sol#L83-L92) uses assembly
	- [INLINE ASM](contracts/vendor/AaveV3/WadRayMath.sol#L85-L91)

contracts/vendor/AaveV3/WadRayMath.sol#L83-L92


 - [ ] ID-67
[SafeERC20._callOptionalReturnBool(IERC20,bytes)](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L201-L211) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L205-L209)

lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L201-L211


 - [ ] ID-68
[Math.tryModExp(bytes,bytes,bytes)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L449-L471) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L461-L470)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L449-L471


 - [ ] ID-69
[WadRayMath.wadMul(uint256,uint256)](contracts/vendor/AaveV3/WadRayMath.sol#L29-L38) uses assembly
	- [INLINE ASM](contracts/vendor/AaveV3/WadRayMath.sol#L31-L37)

contracts/vendor/AaveV3/WadRayMath.sol#L29-L38


 - [ ] ID-70
[WadRayMath.rayMul(uint256,uint256)](contracts/vendor/AaveV3/WadRayMath.sol#L65-L74) uses assembly
	- [INLINE ASM](contracts/vendor/AaveV3/WadRayMath.sol#L67-L73)

contracts/vendor/AaveV3/WadRayMath.sol#L65-L74


## pragma
Impact: Informational
Confidence: High
 - [ ] ID-71
7 different versions of Solidity are used:
	- Version constraint ^0.8.25 is used by:
		-[^0.8.25](contracts/abstract/AStaticUSDCData.sol#L2)
		-[^0.8.25](contracts/abstract/AStaticUSDTData.sol#L2)
		-[^0.8.25](contracts/interfaces/IProtocolAdapter.sol#L2)
		-[^0.8.25](contracts/interfaces/IVaultShares.sol#L2)
		-[^0.8.25](contracts/protocol/AIAgentVaultManager.sol#L2)
		-[^0.8.25](contracts/protocol/VaultShares.sol#L2)
		-[^0.8.25](contracts/protocol/investableUniverseAdapters/AaveAdapter.sol#L2)
		-[^0.8.25](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L2)
		-[^0.8.25](contracts/vendor/AaveV3/DataTypes.sol#L2)
		-[^0.8.25](contracts/vendor/AaveV3/IPool.sol#L2)
		-[^0.8.25](contracts/vendor/UniswapV2/IUniswapV2Factory.sol#L2)
		-[^0.8.25](contracts/vendor/UniswapV2/IUniswapV2Router01.sol#L2)
	- Version constraint ^0.8.0 is used by:
		-[^0.8.0](contracts/vendor/AaveV3/WadRayMath.sol#L2)
	- Version constraint >=0.5.0 is used by:
		-[>=0.5.0](contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L2)
	- Version constraint ^0.8.20 is used by:
		-[^0.8.20](lib/openzeppelin-contracts/contracts/access/Ownable.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/utils/Context.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/utils/Panic.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L5)
	- Version constraint >=0.6.2 is used by:
		-[>=0.6.2](lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#L4)
		-[>=0.6.2](lib/openzeppelin-contracts/contracts/interfaces/IERC4626.sol#L4)
		-[>=0.6.2](lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol#L4)
	- Version constraint >=0.4.16 is used by:
		-[>=0.4.16](lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#L4)
		-[>=0.4.16](lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol#L4)
		-[>=0.4.16](lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol#L4)
		-[>=0.4.16](lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#L4)
	- Version constraint >=0.8.4 is used by:
		-[>=0.8.4](lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#L3)

contracts/abstract/AStaticUSDCData.sol#L2


## solc-version
Impact: Informational
Confidence: High
 - [ ] ID-72
Version constraint >=0.8.4 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess
	- AbiReencodingHeadOverflowWithStaticArrayCleanup
	- DirtyBytesArrayToStorage
	- DataLocationChangeInInternalOverride
	- NestedCalldataArrayAbiReencodingSizeValidation
	- SignedImmutables.
It is used by:
	- [>=0.8.4](lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#L3)

lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#L3


 - [ ] ID-73
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
	- [>=0.4.16](lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#L4)
	- [>=0.4.16](lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol#L4)
	- [>=0.4.16](lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol#L4)
	- [>=0.4.16](lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#L4)

lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#L4


 - [ ] ID-74
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
	- [>=0.5.0](contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L2)

contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L2


 - [ ] ID-75
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
	- [^0.8.0](contracts/vendor/AaveV3/WadRayMath.sol#L2)

contracts/vendor/AaveV3/WadRayMath.sol#L2


 - [ ] ID-76
Version constraint ^0.8.20 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess.
It is used by:
	- [^0.8.20](lib/openzeppelin-contracts/contracts/access/Ownable.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/Context.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/Panic.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol#L5)

lib/openzeppelin-contracts/contracts/access/Ownable.sol#L4


 - [ ] ID-77
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
	- [>=0.6.2](lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#L4)
	- [>=0.6.2](lib/openzeppelin-contracts/contracts/interfaces/IERC4626.sol#L4)
	- [>=0.6.2](lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol#L4)

lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol#L4


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-78
Low level call in [ERC4626._tryGetAssetDecimals(IERC20)](lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L86-L97):
	- [(success,encodedDecimals) = address(asset_).staticcall(abi.encodeCall(IERC20Metadata.decimals,()))](lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L87-L89)

lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol#L86-L97


 - [ ] ID-79
Low level call in [AIAgentVaultManager.execute(uint256,uint256,bytes)](contracts/protocol/AIAgentVaultManager.sol#L227-L251):
	- [(success,result) = address(adapter).call{value: value}(data)](contracts/protocol/AIAgentVaultManager.sol#L241-L243)

contracts/protocol/AIAgentVaultManager.sol#L227-L251


 - [ ] ID-80
Low level call in [AIAgentVaultManager.executeBatch(uint256[],uint256[],bytes[])](contracts/protocol/AIAgentVaultManager.sol#L260-L302):
	- [(success,result) = target.call{value: values[i]}(data[i])](contracts/protocol/AIAgentVaultManager.sol#L292-L294)

contracts/protocol/AIAgentVaultManager.sol#L260-L302


## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-81
Variable [VaultShares.i_Fee](contracts/protocol/VaultShares.sol#L40) is not in mixedCase

contracts/protocol/VaultShares.sol#L40


 - [ ] ID-82
Variable [AaveAdapter.i_aavePool](contracts/protocol/investableUniverseAdapters/AaveAdapter.sol#L16) is not in mixedCase

contracts/protocol/investableUniverseAdapters/AaveAdapter.sol#L16


 - [ ] ID-83
Function [IUniswapV2Pair.PERMIT_TYPEHASH()](contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L35) is not in mixedCase

contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L35


 - [ ] ID-84
Function [IUniswapV2Pair.MINIMUM_LIQUIDITY()](contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L66) is not in mixedCase

contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L66


 - [ ] ID-85
Function [IUniswapV2Pair.DOMAIN_SEPARATOR()](contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L33) is not in mixedCase

contracts/vendor/UniswapV2/IUniswapV2Pair.sol#L33


 - [ ] ID-86
Variable [UniswapAdapter.s_tokenConfigs](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L31) is not in mixedCase

contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L31


 - [ ] ID-87
Function [IUniswapV2Router01.WETH()](contracts/vendor/UniswapV2/IUniswapV2Router01.sol#L9) is not in mixedCase

contracts/vendor/UniswapV2/IUniswapV2Router01.sol#L9


 - [ ] ID-88
Constant [AIAgentVaultManager.s_Fee](contracts/protocol/AIAgentVaultManager.sol#L26) is not in UPPER_CASE_WITH_UNDERSCORES

contracts/protocol/AIAgentVaultManager.sol#L26


 - [ ] ID-89
Variable [AStaticUSDCData.i_USDC](contracts/abstract/AStaticUSDCData.sol#L9) is not in mixedCase

contracts/abstract/AStaticUSDCData.sol#L9


 - [ ] ID-90
Function [UniswapAdapter.UpdateTokenCounterPartyToken(IERC20,IERC20)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L112-L128) is not in mixedCase

contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L112-L128


 - [ ] ID-91
Function [UniswapAdapter.UpdateTokenSlippageTolerance(IERC20,uint256)](contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L89-L105) is not in mixedCase

contracts/protocol/investableUniverseAdapters/UniswapV2Adapter.sol#L89-L105


## too-many-digits
Impact: Informational
Confidence: Medium
 - [ ] ID-92
[Math.log2(uint256)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L612-L651) uses literals with too many digits:
	- [r = r | byte(uint256,uint256)(x >> r,0x0000010102020202030303030303030300000000000000000000000000000000)](lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L649)

lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L612-L651


