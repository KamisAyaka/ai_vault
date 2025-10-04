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

// UniswapV2Adapter handles UniswapV2 adapter configuration via VaultManager.execute()
type UniswapV2Adapter struct {
	executeFunc func(ctx context.Context, adapterIndex uint64, value uint64, data []byte) (string, error)
}

// NewUniswapV2Adapter creates a new UniswapV2 adapter config helper
func NewUniswapV2Adapter(executeFunc func(ctx context.Context, adapterIndex uint64, value uint64, data []byte) (string, error)) *UniswapV2Adapter {
	return &UniswapV2Adapter{executeFunc: executeFunc}
}

// SetTokenConfig configures token for UniswapV2 adapter
// Calls: VaultManager.execute(adapterIndex, 0, abi.encode("setTokenConfig(...)", ...))
func (u *UniswapV2Adapter) SetTokenConfig(ctx context.Context, adapterIndex uint64, tokenAddress string, slippageTolerance uint64, counterPartyToken, vaultAddress string) (string, error) {
	logger.Log.WithFields(logrus.Fields{
		"adapter_index": adapterIndex,
		"token":         tokenAddress,
		"slippage":      slippageTolerance,
		"counter_party": counterPartyToken,
		"vault":         vaultAddress,
	}).Info("Configuring UniswapV2 adapter: setTokenConfig")

	// Build ABI (from compiled contract)
	abiJSON := `[{"inputs":[{"internalType":"contract IERC20","name":"token","type":"address"},{"internalType":"uint256","name":"slippageTolerance","type":"uint256"},{"internalType":"contract IERC20","name":"counterPartyToken","type":"address"},{"internalType":"address","name":"VaultAddress","type":"address"}],"name":"setTokenConfig","outputs":[],"stateMutability":"nonpayable","type":"function"}]`
	parsedABI, err := abi.JSON(strings.NewReader(abiJSON))
	if err != nil {
		return "", err
	}

	// Encode function call
	token := common.HexToAddress(tokenAddress)
	slippage := new(big.Int).SetUint64(slippageTolerance)
	counterParty := common.HexToAddress(counterPartyToken)
	vault := common.HexToAddress(vaultAddress)

	data, err := parsedABI.Pack("setTokenConfig", token, slippage, counterParty, vault)
	if err != nil {
		return "", err
	}

	return u.executeFunc(ctx, adapterIndex, 0, data)
}

// UpdateTokenSlippageTolerance updates only the slippage tolerance
func (u *UniswapV2Adapter) UpdateTokenSlippageTolerance(ctx context.Context, adapterIndex uint64, tokenAddress string, slippageTolerance uint64) (string, error) {
	logger.Log.WithFields(logrus.Fields{
		"adapter_index": adapterIndex,
		"token":         tokenAddress,
		"slippage":      slippageTolerance,
	}).Info("Updating UniswapV2 adapter: UpdateTokenSlippageTolerance")

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

// UpdateTokenConfigAndReinvest updates counterPartyToken and reinvests liquidity
// This should be used after initial deployment when changing LP pair configuration
func (u *UniswapV2Adapter) UpdateTokenConfigAndReinvest(ctx context.Context, adapterIndex uint64, tokenAddress, counterPartyToken string) (string, error) {
	logger.Log.WithFields(logrus.Fields{
		"adapter_index": adapterIndex,
		"token":         tokenAddress,
		"counter_party": counterPartyToken,
	}).Info("Updating UniswapV2 adapter: updateTokenConfigAndReinvest")

	abiJSON := `[{"inputs":[{"internalType":"contract IERC20","name":"token","type":"address"},{"internalType":"contract IERC20","name":"counterPartyToken","type":"address"}],"name":"updateTokenConfigAndReinvest","outputs":[],"stateMutability":"nonpayable","type":"function"}]`
	parsedABI, err := abi.JSON(strings.NewReader(abiJSON))
	if err != nil {
		return "", err
	}

	token := common.HexToAddress(tokenAddress)
	counterParty := common.HexToAddress(counterPartyToken)

	data, err := parsedABI.Pack("updateTokenConfigAndReinvest", token, counterParty)
	if err != nil {
		return "", err
	}

	return u.executeFunc(ctx, adapterIndex, 0, data)
}
