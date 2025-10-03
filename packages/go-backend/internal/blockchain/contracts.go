package blockchain

import (
	"context"
	"fmt"
	"math/big"

	"ai-vault-backend/internal/config"
	"ai-vault-backend/internal/database"
	"ai-vault-backend/internal/logger"

	"github.com/ethereum/go-ethereum/common"
	"github.com/sirupsen/logrus"
)

// ContractService handles smart contract interactions
type ContractService struct {
	client           *Client
	cfg              config.BlockchainConfig
	vaultManagerAddr common.Address
	wethAddr         common.Address
}

// NewContractService creates a new contract service
func NewContractService(client *Client, cfg config.BlockchainConfig) (*ContractService, error) {
	if cfg.VaultManagerAddress == "" || cfg.WETHAddress == "" {
		return nil, fmt.Errorf("vault manager and WETH addresses must be configured")
	}

	return &ContractService{
		client:           client,
		cfg:              cfg,
		vaultManagerAddr: common.HexToAddress(cfg.VaultManagerAddress),
		wethAddr:         common.HexToAddress(cfg.WETHAddress),
	}, nil
}

// ExecuteStrategy executes an AI strategy on the vault manager
func (cs *ContractService) ExecuteStrategy(ctx context.Context, strategy *database.Strategy, vault *database.Vault) (*database.Execution, error) {
	logger.Log.WithFields(logrus.Fields{
		"strategy_id": strategy.ID,
		"vault_id":    vault.ID,
	}).Info("Executing strategy")

	// Create execution record
	execution := &database.Execution{
		StrategyID: strategy.ID,
		VaultID:    vault.ID,
		Status:     "executing",
	}

	// Convert allocations to contract format
	adapterIndices, allocationData := cs.prepareAllocationData(strategy.Allocations)

	// Prepare transaction data for updateHoldingAllocation
	data, err := cs.encodeUpdateHoldingAllocationData(adapterIndices, allocationData)
	if err != nil {
		execution.Status = "failed"
		execution.Error = fmt.Sprintf("Failed to encode transaction data: %v", err)
		return execution, err
	}

	// Send transaction
	tx, err := cs.client.SendTransaction(ctx, cs.vaultManagerAddr, big.NewInt(0), data)
	if err != nil {
		execution.Status = "failed"
		execution.Error = fmt.Sprintf("Failed to send transaction: %v", err)
		return execution, err
	}

	execution.TxHash = tx.Hash().Hex()

	// Wait for transaction confirmation
	receipt, err := cs.client.WaitForTransaction(ctx, tx.Hash())
	if err != nil {
		execution.Status = "failed"
		execution.Error = fmt.Sprintf("Failed to wait for transaction: %v", err)
		return execution, err
	}

	// Update execution with receipt data
	execution.GasUsed = receipt.GasUsed
	execution.GasPrice = tx.GasPrice().String()
	execution.Status = "completed"

	logger.Log.WithFields(logrus.Fields{
		"execution_id": execution.ID,
		"tx_hash":      execution.TxHash,
		"gas_used":     execution.GasUsed,
	}).Info("Strategy executed successfully")

	return execution, nil
}

// ExecutePartialStrategy executes a partial strategy update
func (cs *ContractService) ExecutePartialStrategy(ctx context.Context, strategy *database.Strategy, vault *database.Vault,
	divestIndices []int, divestAmounts []*big.Int, investIndices []int, investAmounts []*big.Int, investAllocations []int) (*database.Execution, error) {

	logger.Log.WithFields(logrus.Fields{
		"strategy_id": strategy.ID,
		"vault_id":    vault.ID,
	}).Info("Executing partial strategy")

	execution := &database.Execution{
		StrategyID: strategy.ID,
		VaultID:    vault.ID,
		Status:     "executing",
	}

	// Prepare transaction data for partialUpdateHoldingAllocation
	data, err := cs.encodePartialUpdateHoldingAllocationData(
		divestIndices, divestAmounts, investIndices, investAmounts, investAllocations)
	if err != nil {
		execution.Status = "failed"
		execution.Error = fmt.Sprintf("Failed to encode transaction data: %v", err)
		return execution, err
	}

	// Send transaction
	tx, err := cs.client.SendTransaction(ctx, cs.vaultManagerAddr, big.NewInt(0), data)
	if err != nil {
		execution.Status = "failed"
		execution.Error = fmt.Sprintf("Failed to send transaction: %v", err)
		return execution, err
	}

	execution.TxHash = tx.Hash().Hex()

	// Wait for transaction confirmation
	receipt, err := cs.client.WaitForTransaction(ctx, tx.Hash())
	if err != nil {
		execution.Status = "failed"
		execution.Error = fmt.Sprintf("Failed to wait for transaction: %v", err)
		return execution, err
	}

	execution.GasUsed = receipt.GasUsed
	execution.GasPrice = tx.GasPrice().String()
	execution.Status = "completed"

	return execution, nil
}

// WithdrawAllInvestments withdraws all investments from a vault
func (cs *ContractService) WithdrawAllInvestments(ctx context.Context, vault *database.Vault) (*database.Execution, error) {
	execution := &database.Execution{
		VaultID: vault.ID,
		Status:  "executing",
	}

	// Prepare transaction data for withdrawAllInvestments
	data, err := cs.encodeWithdrawAllInvestmentsData()
	if err != nil {
		execution.Status = "failed"
		execution.Error = fmt.Sprintf("Failed to encode transaction data: %v", err)
		return execution, err
	}

	// Send transaction
	tx, err := cs.client.SendTransaction(ctx, cs.vaultManagerAddr, big.NewInt(0), data)
	if err != nil {
		execution.Status = "failed"
		execution.Error = fmt.Sprintf("Failed to send transaction: %v", err)
		return execution, err
	}

	execution.TxHash = tx.Hash().Hex()

	// Wait for transaction confirmation
	receipt, err := cs.client.WaitForTransaction(ctx, tx.Hash())
	if err != nil {
		execution.Status = "failed"
		execution.Error = fmt.Sprintf("Failed to wait for transaction: %v", err)
		return execution, err
	}

	execution.GasUsed = receipt.GasUsed
	execution.GasPrice = tx.GasPrice().String()
	execution.Status = "completed"

	return execution, nil
}

// prepareAllocationData converts database allocations to contract format
func (cs *ContractService) prepareAllocationData(allocations []database.Allocation) ([]*big.Int, []*big.Int) {
	adapterIndices := make([]*big.Int, len(allocations))
	allocationData := make([]*big.Int, len(allocations))

	for i, allocation := range allocations {
		adapterIndices[i] = big.NewInt(int64(allocation.AdapterIndex))
		allocationData[i] = big.NewInt(int64(allocation.Percentage))
	}

	return adapterIndices, allocationData
}

// encodeUpdateHoldingAllocationData encodes the updateHoldingAllocation function call
func (cs *ContractService) encodeUpdateHoldingAllocationData(adapterIndices []*big.Int, allocationData []*big.Int) ([]byte, error) {
	// Function selector for updateHoldingAllocation(IERC20,uint256[],uint256[])
	functionSelector := []byte{0x8b, 0x7f, 0x8c, 0x5d}

	// Encode parameters
	// Note: This is a simplified encoding. In production, you'd want to use proper ABI encoding
	// For now, we'll create a basic encoding structure
	var data []byte
	data = append(data, functionSelector...)

	// Add WETH address (32 bytes)
	data = append(data, common.LeftPadBytes(cs.wethAddr.Bytes(), 32)...)

	// Add array lengths and data
	// This is a simplified approach - in production, use proper ABI encoding library
	data = append(data, common.LeftPadBytes(big.NewInt(int64(len(adapterIndices))).Bytes(), 32)...)

	return data, nil
}

// encodePartialUpdateHoldingAllocationData encodes the partialUpdateHoldingAllocation function call
func (cs *ContractService) encodePartialUpdateHoldingAllocationData(
	divestIndices []int, divestAmounts []*big.Int, investIndices []int, investAmounts []*big.Int, investAllocations []int) ([]byte, error) {

	// Function selector for partialUpdateHoldingAllocation
	functionSelector := []byte{0x1a, 0x2b, 0x3c, 0x4d} // Placeholder - replace with actual selector

	var data []byte
	data = append(data, functionSelector...)

	// Add WETH address
	data = append(data, common.LeftPadBytes(cs.wethAddr.Bytes(), 32)...)

	// Add array data (simplified)
	data = append(data, common.LeftPadBytes(big.NewInt(int64(len(divestIndices))).Bytes(), 32)...)

	return data, nil
}

// encodeWithdrawAllInvestmentsData encodes the withdrawAllInvestments function call
func (cs *ContractService) encodeWithdrawAllInvestmentsData() ([]byte, error) {
	// Function selector for withdrawAllInvestments(IERC20)
	functionSelector := []byte{0x2e, 0x1a, 0x7d, 0x4d} // Placeholder - replace with actual selector

	var data []byte
	data = append(data, functionSelector...)

	// Add WETH address
	data = append(data, common.LeftPadBytes(cs.wethAddr.Bytes(), 32)...)

	return data, nil
}

// GetVaultInfo retrieves vault information from the blockchain
func (cs *ContractService) GetVaultInfo(ctx context.Context, vaultAddress common.Address) (*VaultInfo, error) {
	// This would involve calling view functions on the vault contract
	// For now, return a placeholder structure
	return &VaultInfo{
		Address:     vaultAddress.Hex(),
		TotalAssets: "0",
		IsActive:    true,
	}, nil
}

// VaultInfo represents vault information from the blockchain
type VaultInfo struct {
	Address     string `json:"address"`
	TotalAssets string `json:"total_assets"`
	IsActive    bool   `json:"is_active"`
}
