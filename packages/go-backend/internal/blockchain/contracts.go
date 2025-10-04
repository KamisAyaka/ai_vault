package blockchain

import (
	"context"
	"fmt"
	"math/big"

	"ai-vault-backend/internal/blockchain/adapters"
	"ai-vault-backend/internal/config"
	"ai-vault-backend/internal/logger"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/sirupsen/logrus"
)

// ContractService handles smart contract interactions
type ContractService struct {
	client           *Client
	cfg              config.BlockchainConfig
	vaultManager     *VaultManager
	vaultManagerAddr common.Address

	// Adapter helpers
	Aave      *adapters.AaveAdapter
	UniswapV2 *adapters.UniswapV2Adapter
	UniswapV3 *adapters.UniswapV3Adapter
}

// AllocationRequest represents a single allocation from the API
type AllocationRequest struct {
	AdapterIndex uint64 `json:"adapter_index"` // Index in the global adapter list
	Percentage   uint64 `json:"percentage"`    // Allocation percentage (0-10000 for 0-100%)
}

// NewContractService creates a new contract service
func NewContractService(client *Client, cfg config.BlockchainConfig) (*ContractService, error) {
	if cfg.VaultManagerAddress == "" {
		return nil, fmt.Errorf("vault manager address must be configured")
	}

	vaultManagerAddr := common.HexToAddress(cfg.VaultManagerAddress)

	// Create contract binding
	vaultManager, err := NewVaultManager(vaultManagerAddr, client.client)
	if err != nil {
		return nil, fmt.Errorf("failed to create vault manager binding: %w", err)
	}

	cs := &ContractService{
		client:           client,
		cfg:              cfg,
		vaultManager:     vaultManager,
		vaultManagerAddr: vaultManagerAddr,
	}

	// Initialize adapter helpers
	cs.Aave = adapters.NewAaveAdapter(cs.executeAdapterCall)
	cs.UniswapV2 = adapters.NewUniswapV2Adapter(cs.executeAdapterCall)
	cs.UniswapV3 = adapters.NewUniswapV3Adapter(cs.executeAdapterCall)

	return cs, nil
}

// UpdateVaultAllocations updates the allocations for a vault
// This calls AIAgentVaultManager.updateHoldingAllocation(token, adapterIndices, allocationData)
func (cs *ContractService) UpdateVaultAllocations(ctx context.Context, tokenAddress string, allocations []AllocationRequest) (string, error) {
	logger.Log.WithFields(logrus.Fields{
		"token_address": tokenAddress,
		"allocations":   allocations,
	}).Info("Updating vault allocations via VaultManager")

	// Convert to contract parameters
	adapterIndices := make([]*big.Int, len(allocations))
	allocationData := make([]*big.Int, len(allocations))

	for i, alloc := range allocations {
		adapterIndices[i] = new(big.Int).SetUint64(alloc.AdapterIndex)
		allocationData[i] = new(big.Int).SetUint64(alloc.Percentage)
	}

	// Get transactor options
	auth, err := cs.client.GetTransactOpts(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to get transactor options: %w", err)
	}

	// Call updateHoldingAllocation on VaultManager
	tokenAddr := common.HexToAddress(tokenAddress)
	tx, err := cs.vaultManager.UpdateHoldingAllocation(auth, tokenAddr, adapterIndices, allocationData)
	if err != nil {
		return "", fmt.Errorf("failed to call updateHoldingAllocation: %w", err)
	}

	logger.Log.WithFields(logrus.Fields{
		"token_address": tokenAddress,
		"tx_hash":       tx.Hash().Hex(),
	}).Info("Vault allocations update transaction sent")

	return tx.Hash().Hex(), nil
}

// WithdrawAllInvestments withdraws all investments from a vault
// This calls AIAgentVaultManager.withdrawAllInvestments(token)
func (cs *ContractService) WithdrawAllInvestments(ctx context.Context, tokenAddress string) (string, error) {
	logger.Log.WithField("token_address", tokenAddress).Info("Withdrawing all investments via VaultManager")

	// Get transactor options
	auth, err := cs.client.GetTransactOpts(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to get transactor options: %w", err)
	}

	// Call withdrawAllInvestments on VaultManager
	tokenAddr := common.HexToAddress(tokenAddress)
	tx, err := cs.vaultManager.WithdrawAllInvestments(auth, tokenAddr)
	if err != nil {
		return "", fmt.Errorf("failed to call withdrawAllInvestments: %w", err)
	}

	logger.Log.WithFields(logrus.Fields{
		"token_address": tokenAddress,
		"tx_hash":       tx.Hash().Hex(),
	}).Info("Withdraw all investments transaction sent")

	return tx.Hash().Hex(), nil
}

// WaitForTransaction waits for a transaction to be mined and returns the receipt
func (cs *ContractService) WaitForTransaction(ctx context.Context, txHash string) (*types.Receipt, error) {
	hash := common.HexToHash(txHash)
	return cs.client.WaitForTransaction(ctx, hash)
}

// executeAdapterCall is the internal method that calls VaultManager.execute()
// This is used by adapter helpers to configure adapter-specific parameters
func (cs *ContractService) executeAdapterCall(ctx context.Context, adapterIndex uint64, value uint64, data []byte) (string, error) {
	logger.Log.WithFields(logrus.Fields{
		"adapter_index": adapterIndex,
		"value":         value,
		"data_length":   len(data),
	}).Info("Executing adapter call via VaultManager.execute()")

	// Get transactor options
	auth, err := cs.client.GetTransactOpts(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to get transactor options: %w", err)
	}

	// Set value if sending ETH
	auth.Value = new(big.Int).SetUint64(value)

	// Call VaultManager.execute(adapterIndex, value, data)
	tx, err := cs.vaultManager.Execute(
		auth,
		new(big.Int).SetUint64(adapterIndex),
		new(big.Int).SetUint64(value),
		data,
	)
	if err != nil {
		return "", fmt.Errorf("failed to execute adapter call: %w", err)
	}

	logger.Log.WithFields(logrus.Fields{
		"adapter_index": adapterIndex,
		"tx_hash":       tx.Hash().Hex(),
	}).Info("Adapter configuration transaction sent")

	return tx.Hash().Hex(), nil
}
