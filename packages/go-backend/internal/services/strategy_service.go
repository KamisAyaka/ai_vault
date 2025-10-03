package services

import (
	"context"
	"fmt"
	"time"

	"ai-vault-backend/internal/blockchain"
	"ai-vault-backend/internal/database"
	"ai-vault-backend/internal/logger"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
	"gorm.io/gorm"
)

// StrategyService handles strategy-related operations
type StrategyService struct {
	db              *gorm.DB
	contractService *blockchain.ContractService
}

// NewStrategyService creates a new strategy service
func NewStrategyService(db *gorm.DB, contractService *blockchain.ContractService) *StrategyService {
	return &StrategyService{
		db:              db,
		contractService: contractService,
	}
}

// CreateStrategyRequest represents the request to create a strategy
type CreateStrategyRequest struct {
	Name        string                    `json:"name" binding:"required"`
	Description string                    `json:"description"`
	Allocations []CreateAllocationRequest `json:"allocations" binding:"required"`
}

// CreateAllocationRequest represents an allocation in the strategy
type CreateAllocationRequest struct {
	AdapterIndex int    `json:"adapter_index" binding:"required"`
	Percentage   int    `json:"percentage" binding:"required,min=0,max=1000"`
	Protocol     string `json:"protocol" binding:"required"`
}

// ExecuteStrategyRequest represents the request to execute a strategy
type ExecuteStrategyRequest struct {
	StrategyID uuid.UUID `json:"strategy_id" binding:"required"`
	VaultID    uuid.UUID `json:"vault_id" binding:"required"`
}

// CreateStrategy creates a new strategy
func (s *StrategyService) CreateStrategy(req *CreateStrategyRequest) (*database.Strategy, error) {
	strategy := &database.Strategy{
		Name:        req.Name,
		Description: req.Description,
		Status:      "pending",
	}

	// Create strategy
	if err := s.db.Create(strategy).Error; err != nil {
		return nil, fmt.Errorf("failed to create strategy: %w", err)
	}

	// Create allocations
	for _, allocReq := range req.Allocations {
		allocation := &database.Allocation{
			StrategyID:   strategy.ID,
			AdapterIndex: allocReq.AdapterIndex,
			Percentage:   allocReq.Percentage,
			Protocol:     allocReq.Protocol,
		}
		if err := s.db.Create(allocation).Error; err != nil {
			return nil, fmt.Errorf("failed to create allocation: %w", err)
		}
		strategy.Allocations = append(strategy.Allocations, *allocation)
	}

	logger.Log.WithFields(logrus.Fields{
		"strategy_id": strategy.ID,
		"name":        strategy.Name,
	}).Info("Strategy created successfully")

	return strategy, nil
}

// GetStrategy retrieves a strategy by ID
func (s *StrategyService) GetStrategy(id uuid.UUID) (*database.Strategy, error) {
	var strategy database.Strategy
	if err := s.db.Preload("Allocations").First(&strategy, "id = ?", id).Error; err != nil {
		return nil, fmt.Errorf("strategy not found: %w", err)
	}
	return &strategy, nil
}

// ListStrategies retrieves all strategies with pagination
func (s *StrategyService) ListStrategies(limit, offset int) ([]database.Strategy, error) {
	var strategies []database.Strategy
	if err := s.db.Preload("Allocations").
		Limit(limit).Offset(offset).
		Order("created_at DESC").
		Find(&strategies).Error; err != nil {
		return nil, fmt.Errorf("failed to list strategies: %w", err)
	}
	return strategies, nil
}

// ExecuteStrategy executes a strategy on a vault
func (s *StrategyService) ExecuteStrategy(ctx context.Context, req *ExecuteStrategyRequest) (*database.Execution, error) {
	// Get strategy
	strategy, err := s.GetStrategy(req.StrategyID)
	if err != nil {
		return nil, fmt.Errorf("failed to get strategy: %w", err)
	}

	// Get vault
	vault, err := s.GetVault(req.VaultID)
	if err != nil {
		return nil, fmt.Errorf("failed to get vault: %w", err)
	}

	// Validate strategy can be executed
	if strategy.Status != "pending" {
		return nil, fmt.Errorf("strategy is not in pending status")
	}

	// Update strategy status
	strategy.Status = "executing"
	strategy.ExecutedAt = &time.Time{}
	*strategy.ExecutedAt = time.Now()
	if err := s.db.Save(strategy).Error; err != nil {
		return nil, fmt.Errorf("failed to update strategy status: %w", err)
	}

	// Execute strategy on blockchain
	execution, err := s.contractService.ExecuteStrategy(ctx, strategy, vault)
	if err != nil {
		// Update strategy status to failed
		strategy.Status = "failed"
		s.db.Save(strategy)
		return nil, fmt.Errorf("failed to execute strategy on blockchain: %w", err)
	}

	// Save execution to database
	if err := s.db.Create(execution).Error; err != nil {
		return nil, fmt.Errorf("failed to save execution: %w", err)
	}

	// Update strategy status to completed
	strategy.Status = "completed"
	if err := s.db.Save(strategy).Error; err != nil {
		logger.Log.Errorf("Failed to update strategy status to completed: %v", err)
	}

	logger.Log.WithFields(logrus.Fields{
		"execution_id": execution.ID,
		"strategy_id":  strategy.ID,
		"vault_id":     vault.ID,
		"tx_hash":      execution.TxHash,
	}).Info("Strategy executed successfully")

	return execution, nil
}

// GetVault retrieves a vault by ID
func (s *StrategyService) GetVault(id uuid.UUID) (*database.Vault, error) {
	var vault database.Vault
	if err := s.db.First(&vault, "id = ?", id).Error; err != nil {
		return nil, fmt.Errorf("vault not found: %w", err)
	}
	return &vault, nil
}

// ListVaults retrieves all vaults with pagination
func (s *StrategyService) ListVaults(limit, offset int) ([]database.Vault, error) {
	var vaults []database.Vault
	if err := s.db.Limit(limit).Offset(offset).
		Order("created_at DESC").
		Find(&vaults).Error; err != nil {
		return nil, fmt.Errorf("failed to list vaults: %w", err)
	}
	return vaults, nil
}

// GetExecution retrieves an execution by ID
func (s *StrategyService) GetExecution(id uuid.UUID) (*database.Execution, error) {
	var execution database.Execution
	if err := s.db.Preload("Strategy").Preload("Vault").
		First(&execution, "id = ?", id).Error; err != nil {
		return nil, fmt.Errorf("execution not found: %w", err)
	}
	return &execution, nil
}

// ListExecutions retrieves all executions with pagination
func (s *StrategyService) ListExecutions(limit, offset int) ([]database.Execution, error) {
	var executions []database.Execution
	if err := s.db.Preload("Strategy").Preload("Vault").
		Limit(limit).Offset(offset).
		Order("created_at DESC").
		Find(&executions).Error; err != nil {
		return nil, fmt.Errorf("failed to list executions: %w", err)
	}
	return executions, nil
}

// WithdrawAllInvestments withdraws all investments from a vault
func (s *StrategyService) WithdrawAllInvestments(ctx context.Context, vaultID uuid.UUID) (*database.Execution, error) {
	// Get vault
	vault, err := s.GetVault(vaultID)
	if err != nil {
		return nil, fmt.Errorf("failed to get vault: %w", err)
	}

	// Execute withdrawal on blockchain
	execution, err := s.contractService.WithdrawAllInvestments(ctx, vault)
	if err != nil {
		return nil, fmt.Errorf("failed to withdraw investments: %w", err)
	}

	// Save execution to database
	if err := s.db.Create(execution).Error; err != nil {
		return nil, fmt.Errorf("failed to save execution: %w", err)
	}

	return execution, nil
}
