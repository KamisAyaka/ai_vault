package services

import (
	"context"

	"ai-vault-backend/internal/blockchain"
	"ai-vault-backend/internal/logger"

	"github.com/sirupsen/logrus"
)

// VaultService handles vault-related operations
type VaultService struct {
	contractService *blockchain.ContractService
}

// NewVaultService creates a new vault service
func NewVaultService(contractService *blockchain.ContractService) *VaultService {
	return &VaultService{
		contractService: contractService,
	}
}

// UpdateAllocationsRequest represents the request to update vault allocations
type UpdateAllocationsRequest struct {
	TokenAddress string                           `json:"token_address" binding:"required"` // Vault asset token address (e.g. WETH)
	Allocations  []blockchain.AllocationRequest `json:"allocations" binding:"required"`
}

// UpdateAllocationsResponse represents the response after updating allocations
type UpdateAllocationsResponse struct {
	TxHash string `json:"tx_hash"`
	Status string `json:"status"`
}

// UpdateAllocations updates the allocations for a vault
func (s *VaultService) UpdateAllocations(ctx context.Context, req *UpdateAllocationsRequest) (*UpdateAllocationsResponse, error) {
	logger.Log.WithFields(logrus.Fields{
		"token_address": req.TokenAddress,
		"allocations":   req.Allocations,
	}).Info("Updating vault allocations")

	// Call contract service to update allocations via VaultManager
	txHash, err := s.contractService.UpdateVaultAllocations(ctx, req.TokenAddress, req.Allocations)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to update vault allocations")
		return nil, err
	}

	logger.Log.WithFields(logrus.Fields{
		"token_address": req.TokenAddress,
		"tx_hash":       txHash,
	}).Info("Vault allocations updated successfully")

	return &UpdateAllocationsResponse{
		TxHash: txHash,
		Status: "pending",
	}, nil
}

// WithdrawAllInvestmentsRequest represents the request to withdraw investments
type WithdrawAllInvestmentsRequest struct {
	TokenAddress string `json:"token_address" binding:"required"` // Vault asset token address
}

// WithdrawAllInvestmentsResponse represents the response after withdrawing investments
type WithdrawAllInvestmentsResponse struct {
	TxHash string `json:"tx_hash"`
	Status string `json:"status"`
}

// WithdrawAllInvestments withdraws all investments from a vault
func (s *VaultService) WithdrawAllInvestments(ctx context.Context, req *WithdrawAllInvestmentsRequest) (*WithdrawAllInvestmentsResponse, error) {
	logger.Log.WithField("token_address", req.TokenAddress).Info("Withdrawing all investments")

	// Call contract service to withdraw all investments via VaultManager
	txHash, err := s.contractService.WithdrawAllInvestments(ctx, req.TokenAddress)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to withdraw all investments")
		return nil, err
	}

	logger.Log.WithFields(logrus.Fields{
		"token_address": req.TokenAddress,
		"tx_hash":       txHash,
	}).Info("All investments withdrawn successfully")

	return &WithdrawAllInvestmentsResponse{
		TxHash: txHash,
		Status: "pending",
	}, nil
}

/*//////////////////////////////////////////////////////////////
                    ADAPTER CONFIGURATION
//////////////////////////////////////////////////////////////*/

// ConfigureAaveAdapterRequest represents the request to configure Aave adapter
type ConfigureAaveAdapterRequest struct {
	AdapterIndex uint64 `json:"adapter_index"` // Aave adapter index in global list (can be 0)
	TokenAddress string `json:"token_address" binding:"required"`
	VaultAddress string `json:"vault_address" binding:"required"`
}

// ConfigureAaveAdapter configures Aave adapter via VaultManager.execute()
func (s *VaultService) ConfigureAaveAdapter(ctx context.Context, req *ConfigureAaveAdapterRequest) (*UpdateAllocationsResponse, error) {
	logger.Log.WithFields(logrus.Fields{
		"adapter_index": req.AdapterIndex,
		"token_address": req.TokenAddress,
		"vault_address": req.VaultAddress,
	}).Info("Configuring Aave adapter")

	txHash, err := s.contractService.Aave.SetTokenVault(ctx, req.AdapterIndex, req.TokenAddress, req.VaultAddress)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to configure Aave adapter")
		return nil, err
	}

	logger.Log.WithField("tx_hash", txHash).Info("Aave adapter configured successfully")
	return &UpdateAllocationsResponse{TxHash: txHash, Status: "pending"}, nil
}

// ConfigureUniswapV2AdapterRequest represents the request to configure UniswapV2 adapter
type ConfigureUniswapV2AdapterRequest struct {
	AdapterIndex      uint64 `json:"adapter_index"` // Can be 0
	TokenAddress      string `json:"token_address" binding:"required"`
	SlippageTolerance uint64 `json:"slippage_tolerance" binding:"required"` // basis points, 100 = 1%
	CounterPartyToken string `json:"counter_party_token" binding:"required"`
	VaultAddress      string `json:"vault_address" binding:"required"`
}

// ConfigureUniswapV2Adapter configures UniswapV2 adapter via VaultManager.execute()
func (s *VaultService) ConfigureUniswapV2Adapter(ctx context.Context, req *ConfigureUniswapV2AdapterRequest) (*UpdateAllocationsResponse, error) {
	logger.Log.WithFields(logrus.Fields{
		"adapter_index":      req.AdapterIndex,
		"token_address":      req.TokenAddress,
		"slippage_tolerance": req.SlippageTolerance,
		"counter_party":      req.CounterPartyToken,
		"vault_address":      req.VaultAddress,
	}).Info("Configuring UniswapV2 adapter")

	txHash, err := s.contractService.UniswapV2.SetTokenConfig(
		ctx,
		req.AdapterIndex,
		req.TokenAddress,
		req.SlippageTolerance,
		req.CounterPartyToken,
		req.VaultAddress,
	)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to configure UniswapV2 adapter")
		return nil, err
	}

	logger.Log.WithField("tx_hash", txHash).Info("UniswapV2 adapter configured successfully")
	return &UpdateAllocationsResponse{TxHash: txHash, Status: "pending"}, nil
}

// UpdateUniswapV2SlippageRequest represents the request to update UniswapV2 slippage
type UpdateUniswapV2SlippageRequest struct {
	AdapterIndex      uint64 `json:"adapter_index"` // Can be 0
	TokenAddress      string `json:"token_address" binding:"required"`
	SlippageTolerance uint64 `json:"slippage_tolerance" binding:"required"`
}

// UpdateUniswapV2Slippage updates UniswapV2 slippage tolerance
func (s *VaultService) UpdateUniswapV2Slippage(ctx context.Context, req *UpdateUniswapV2SlippageRequest) (*UpdateAllocationsResponse, error) {
	logger.Log.WithFields(logrus.Fields{
		"adapter_index": req.AdapterIndex,
		"token_address": req.TokenAddress,
		"slippage":      req.SlippageTolerance,
	}).Info("Updating UniswapV2 slippage tolerance")

	txHash, err := s.contractService.UniswapV2.UpdateTokenSlippageTolerance(ctx, req.AdapterIndex, req.TokenAddress, req.SlippageTolerance)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to update UniswapV2 slippage")
		return nil, err
	}

	logger.Log.WithField("tx_hash", txHash).Info("UniswapV2 slippage updated successfully")
	return &UpdateAllocationsResponse{TxHash: txHash, Status: "pending"}, nil
}

// UpdateUniswapV2ConfigRequest represents the request to update UniswapV2 pair and reinvest
type UpdateUniswapV2ConfigRequest struct {
	AdapterIndex      uint64 `json:"adapter_index"` // Can be 0
	TokenAddress      string `json:"token_address" binding:"required"`
	CounterPartyToken string `json:"counter_party_token" binding:"required"`
}

// UpdateUniswapV2Config updates UniswapV2 pair and reinvests
func (s *VaultService) UpdateUniswapV2Config(ctx context.Context, req *UpdateUniswapV2ConfigRequest) (*UpdateAllocationsResponse, error) {
	logger.Log.WithFields(logrus.Fields{
		"adapter_index":  req.AdapterIndex,
		"token_address":  req.TokenAddress,
		"counter_party": req.CounterPartyToken,
	}).Info("Updating UniswapV2 config and reinvesting")

	txHash, err := s.contractService.UniswapV2.UpdateTokenConfigAndReinvest(ctx, req.AdapterIndex, req.TokenAddress, req.CounterPartyToken)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to update UniswapV2 config")
		return nil, err
	}

	logger.Log.WithField("tx_hash", txHash).Info("UniswapV2 config updated successfully")
	return &UpdateAllocationsResponse{TxHash: txHash, Status: "pending"}, nil
}

// ConfigureUniswapV3AdapterRequest represents the request to configure UniswapV3 adapter
type ConfigureUniswapV3AdapterRequest struct {
	AdapterIndex      uint64 `json:"adapter_index"` // Can be 0
	TokenAddress      string `json:"token_address" binding:"required"`
	CounterPartyToken string `json:"counter_party_token" binding:"required"`
	SlippageTolerance uint64 `json:"slippage_tolerance" binding:"required"`
	FeeTier           uint32 `json:"fee_tier" binding:"required"`           // 500=0.05%, 3000=0.3%, 10000=1%
	TickLower         int32  `json:"tick_lower" binding:"required"`
	TickUpper         int32  `json:"tick_upper" binding:"required"`
	VaultAddress      string `json:"vault_address" binding:"required"`
}

// ConfigureUniswapV3Adapter configures UniswapV3 adapter via VaultManager.execute()
func (s *VaultService) ConfigureUniswapV3Adapter(ctx context.Context, req *ConfigureUniswapV3AdapterRequest) (*UpdateAllocationsResponse, error) {
	logger.Log.WithFields(logrus.Fields{
		"adapter_index": req.AdapterIndex,
		"token_address": req.TokenAddress,
		"counter_party": req.CounterPartyToken,
		"fee_tier":      req.FeeTier,
		"tick_lower":    req.TickLower,
		"tick_upper":    req.TickUpper,
	}).Info("Configuring UniswapV3 adapter")

	txHash, err := s.contractService.UniswapV3.SetTokenConfig(
		ctx,
		req.AdapterIndex,
		req.TokenAddress,
		req.CounterPartyToken,
		req.SlippageTolerance,
		req.FeeTier,
		req.TickLower,
		req.TickUpper,
		req.VaultAddress,
	)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to configure UniswapV3 adapter")
		return nil, err
	}

	logger.Log.WithField("tx_hash", txHash).Info("UniswapV3 adapter configured successfully")
	return &UpdateAllocationsResponse{TxHash: txHash, Status: "pending"}, nil
}

// UpdateUniswapV3SlippageRequest represents the request to update UniswapV3 slippage
type UpdateUniswapV3SlippageRequest struct {
	AdapterIndex      uint64 `json:"adapter_index"` // Can be 0
	TokenAddress      string `json:"token_address" binding:"required"`
	SlippageTolerance uint64 `json:"slippage_tolerance" binding:"required"`
}

// UpdateUniswapV3Slippage updates UniswapV3 slippage tolerance
func (s *VaultService) UpdateUniswapV3Slippage(ctx context.Context, req *UpdateUniswapV3SlippageRequest) (*UpdateAllocationsResponse, error) {
	logger.Log.WithFields(logrus.Fields{
		"adapter_index": req.AdapterIndex,
		"token_address": req.TokenAddress,
		"slippage":      req.SlippageTolerance,
	}).Info("Updating UniswapV3 slippage tolerance")

	txHash, err := s.contractService.UniswapV3.UpdateTokenSlippageTolerance(ctx, req.AdapterIndex, req.TokenAddress, req.SlippageTolerance)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to update UniswapV3 slippage")
		return nil, err
	}

	logger.Log.WithField("tx_hash", txHash).Info("UniswapV3 slippage updated successfully")
	return &UpdateAllocationsResponse{TxHash: txHash, Status: "pending"}, nil
}

// UpdateUniswapV3ConfigRequest represents the request to update UniswapV3 position config
type UpdateUniswapV3ConfigRequest struct {
	AdapterIndex      uint64 `json:"adapter_index"` // Can be 0
	TokenAddress      string `json:"token_address" binding:"required"`
	CounterPartyToken string `json:"counter_party_token" binding:"required"`
	FeeTier           uint32 `json:"fee_tier" binding:"required"`
	TickLower         int32  `json:"tick_lower" binding:"required"`
	TickUpper         int32  `json:"tick_upper" binding:"required"`
}

// UpdateUniswapV3Config updates UniswapV3 position config and reinvests
func (s *VaultService) UpdateUniswapV3Config(ctx context.Context, req *UpdateUniswapV3ConfigRequest) (*UpdateAllocationsResponse, error) {
	logger.Log.WithFields(logrus.Fields{
		"adapter_index":  req.AdapterIndex,
		"token_address":  req.TokenAddress,
		"counter_party":  req.CounterPartyToken,
		"fee_tier":       req.FeeTier,
		"tick_lower":     req.TickLower,
		"tick_upper":     req.TickUpper,
	}).Info("Updating UniswapV3 config and reinvesting")

	txHash, err := s.contractService.UniswapV3.UpdateTokenConfig(
		ctx,
		req.AdapterIndex,
		req.TokenAddress,
		req.CounterPartyToken,
		req.FeeTier,
		req.TickLower,
		req.TickUpper,
	)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to update UniswapV3 config")
		return nil, err
	}

	logger.Log.WithField("tx_hash", txHash).Info("UniswapV3 config updated successfully")
	return &UpdateAllocationsResponse{TxHash: txHash, Status: "pending"}, nil
}
