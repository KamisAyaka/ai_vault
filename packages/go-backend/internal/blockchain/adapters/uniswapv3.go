package adapters

import (
	"context"
	"strings"
	"math/big"

	"ai-vault-backend/internal/logger"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/sirupsen/logrus"
)

// UniswapV3Adapter handles UniswapV3 adapter configuration via VaultManager.execute()
type UniswapV3Adapter struct {
	executeFunc func(ctx context.Context, adapterIndex uint64, value uint64, data []byte) (string, error)
}

// NewUniswapV3Adapter creates a new UniswapV3 adapter config helper
func NewUniswapV3Adapter(executeFunc func(ctx context.Context, adapterIndex uint64, value uint64, data []byte) (string, error)) *UniswapV3Adapter {
	return &UniswapV3Adapter{executeFunc: executeFunc}
}

// SetTokenConfig configures token for UniswapV3 adapter
// Calls: VaultManager.execute(adapterIndex, 0, abi.encode("setTokenConfig(...)", ...))
// Parameters: token, counterPartyToken, slippageTolerance, feeTier, tickLower, tickUpper, VaultAddress
func (u *UniswapV3Adapter) SetTokenConfig(ctx context.Context, adapterIndex uint64, tokenAddress, counterPartyToken string, slippageTolerance uint64, feeTier uint32, tickLower, tickUpper int32, vaultAddress string) (string, error) {
	logger.Log.WithFields(logrus.Fields{
		"adapter_index": adapterIndex,
		"token":         tokenAddress,
		"counter_party": counterPartyToken,
		"slippage":      slippageTolerance,
		"fee_tier":      feeTier,
		"tick_lower":    tickLower,
		"tick_upper":    tickUpper,
		"vault":         vaultAddress,
	}).Info("Configuring UniswapV3 adapter: setTokenConfig")

	// Build ABI (from compiled contract)
	abiJSON := `[{"inputs":[{"internalType":"contract IERC20","name":"token","type":"address"},{"internalType":"contract IERC20","name":"counterPartyToken","type":"address"},{"internalType":"uint256","name":"slippageTolerance","type":"uint256"},{"internalType":"uint24","name":"feeTier","type":"uint24"},{"internalType":"int24","name":"tickLower","type":"int24"},{"internalType":"int24","name":"tickUpper","type":"int24"},{"internalType":"address","name":"VaultAddress","type":"address"}],"name":"setTokenConfig","outputs":[],"stateMutability":"nonpayable","type":"function"}]`
	parsedABI, err := abi.JSON(strings.NewReader(abiJSON))
	if err != nil {
		return "", err
	}

	// Encode function call
	token := common.HexToAddress(tokenAddress)
	counterParty := common.HexToAddress(counterPartyToken)
	slippage := new(big.Int).SetUint64(slippageTolerance)
	vault := common.HexToAddress(vaultAddress)

	// Note: uint24 and int24 need special handling
	fee := big.NewInt(int64(feeTier))
	lower := big.NewInt(int64(tickLower))
	upper := big.NewInt(int64(tickUpper))

	data, err := parsedABI.Pack("setTokenConfig", token, counterParty, slippage, fee, lower, upper, vault)
	if err != nil {
		return "", err
	}

	return u.executeFunc(ctx, adapterIndex, 0, data)
}

// UpdateTokenSlippageTolerance updates only the slippage tolerance
func (u *UniswapV3Adapter) UpdateTokenSlippageTolerance(ctx context.Context, adapterIndex uint64, tokenAddress string, slippageTolerance uint64) (string, error) {
	logger.Log.WithFields(logrus.Fields{
		"adapter_index": adapterIndex,
		"token":         tokenAddress,
		"slippage":      slippageTolerance,
	}).Info("Updating UniswapV3 adapter: UpdateTokenSlippageTolerance")

	abiJSON := `[{"inputs":[{"internalType":"contract IERC20","name":"token","type":"address"},{"internalType":"uint256","name":"slippageTolerance","type":"uint256"}],"name":"UpdateTokenSlippageTolerance","outputs":[],"stateMutability":"nonpayable","type":"function"}]`
	parsedABI, err := abi.JSON(strings.NewReader(abiJSON))
	if err != nil {
		return "", err
	}

	token := common.HexToAddress(tokenAddress)
	slippage := new(big.Int).SetUint64(slippageTolerance)

	data, err := parsedABI.Pack("UpdateTokenSlippageTolerance", token, slippage)
	if err != nil {
		return "", err
	}

	return u.executeFunc(ctx, adapterIndex, 0, data)
}

// UpdateTokenConfig updates position parameters (counterPartyToken, feeTier, ticks)
func (u *UniswapV3Adapter) UpdateTokenConfig(ctx context.Context, adapterIndex uint64, tokenAddress, counterPartyToken string, feeTier uint32, tickLower, tickUpper int32) (string, error) {
	logger.Log.WithFields(logrus.Fields{
		"adapter_index": adapterIndex,
		"token":         tokenAddress,
		"counter_party": counterPartyToken,
		"fee_tier":      feeTier,
		"tick_lower":    tickLower,
		"tick_upper":    tickUpper,
	}).Info("Updating UniswapV3 adapter: UpdateTokenConfig")

	abiJSON := `[{"inputs":[{"internalType":"contract IERC20","name":"token","type":"address"},{"internalType":"contract IERC20","name":"counterPartyToken","type":"address"},{"internalType":"uint24","name":"feeTier","type":"uint24"},{"internalType":"int24","name":"tickLower","type":"int24"},{"internalType":"int24","name":"tickUpper","type":"int24"}],"name":"UpdateTokenConfig","outputs":[],"stateMutability":"nonpayable","type":"function"}]`
	parsedABI, err := abi.JSON(strings.NewReader(abiJSON))
	if err != nil {
		return "", err
	}

	token := common.HexToAddress(tokenAddress)
	counterParty := common.HexToAddress(counterPartyToken)

	fee := big.NewInt(int64(feeTier))
	lower := big.NewInt(int64(tickLower))
	upper := big.NewInt(int64(tickUpper))

	data, err := parsedABI.Pack("UpdateTokenConfig", token, counterParty, fee, lower, upper)
	if err != nil {
		return "", err
	}

	return u.executeFunc(ctx, adapterIndex, 0, data)
}
