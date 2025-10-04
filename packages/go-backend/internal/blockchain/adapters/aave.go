package adapters

import (
	"context"
	"strings"

	"ai-vault-backend/internal/logger"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/sirupsen/logrus"
)

// AaveAdapter handles Aave adapter configuration via VaultManager.execute()
type AaveAdapter struct {
	executeFunc func(ctx context.Context, adapterIndex uint64, value uint64, data []byte) (string, error)
}

// NewAaveAdapter creates a new Aave adapter config helper
func NewAaveAdapter(executeFunc func(ctx context.Context, adapterIndex uint64, value uint64, data []byte) (string, error)) *AaveAdapter {
	return &AaveAdapter{executeFunc: executeFunc}
}

// SetTokenVault configures token-vault mapping for Aave adapter
// Calls: VaultManager.execute(adapterIndex, 0, abi.encode("setTokenVault(address,address)", token, vault))
func (a *AaveAdapter) SetTokenVault(ctx context.Context, adapterIndex uint64, tokenAddress, vaultAddress string) (string, error) {
	logger.Log.WithFields(logrus.Fields{
		"adapter_index": adapterIndex,
		"token":         tokenAddress,
		"vault":         vaultAddress,
	}).Info("Configuring Aave adapter: setTokenVault")

	// Build ABI (from compiled contract)
	abiJSON := `[{"inputs":[{"internalType":"contract IERC20","name":"token","type":"address"},{"internalType":"address","name":"vault","type":"address"}],"name":"setTokenVault","outputs":[],"stateMutability":"nonpayable","type":"function"}]`
	parsedABI, err := abi.JSON(strings.NewReader(abiJSON))
	if err != nil {
		return "", err
	}

	// Encode function call
	token := common.HexToAddress(tokenAddress)
	vault := common.HexToAddress(vaultAddress)

	data, err := parsedABI.Pack("setTokenVault", token, vault)
	if err != nil {
		return "", err
	}

	// Execute via VaultManager.execute()
	return a.executeFunc(ctx, adapterIndex, 0, data)
}
