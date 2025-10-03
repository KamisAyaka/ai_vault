package handlers

import (
	"net/http"
	"strconv"

	"ai-vault-backend/internal/logger"
	"ai-vault-backend/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// StrategyHandler handles strategy-related HTTP requests
type StrategyHandler struct {
	strategyService *services.StrategyService
}

// NewStrategyHandler creates a new strategy handler
func NewStrategyHandler(strategyService *services.StrategyService) *StrategyHandler {
	return &StrategyHandler{
		strategyService: strategyService,
	}
}

// CreateStrategy handles POST /api/v1/strategies
func (h *StrategyHandler) CreateStrategy(c *gin.Context) {
	var req services.CreateStrategyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		logger.Log.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	strategy, err := h.strategyService.CreateStrategy(&req)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to create strategy")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create strategy", "details": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":  "Strategy created successfully",
		"strategy": strategy,
	})
}

// GetStrategy handles GET /api/v1/strategies/:id
func (h *StrategyHandler) GetStrategy(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid strategy ID"})
		return
	}

	strategy, err := h.strategyService.GetStrategy(id)
	if err != nil {
		logger.Log.WithError(err).WithField("strategy_id", id).Error("Failed to get strategy")
		c.JSON(http.StatusNotFound, gin.H{"error": "Strategy not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"strategy": strategy})
}

// ListStrategies handles GET /api/v1/strategies
func (h *StrategyHandler) ListStrategies(c *gin.Context) {
	limitStr := c.DefaultQuery("limit", "10")
	offsetStr := c.DefaultQuery("offset", "0")

	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 {
		limit = 10
	}

	offset, err := strconv.Atoi(offsetStr)
	if err != nil || offset < 0 {
		offset = 0
	}

	strategies, err := h.strategyService.ListStrategies(limit, offset)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to list strategies")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list strategies"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"strategies": strategies,
		"limit":      limit,
		"offset":     offset,
	})
}

// ExecuteStrategy handles POST /api/v1/strategies/execute
func (h *StrategyHandler) ExecuteStrategy(c *gin.Context) {
	var req services.ExecuteStrategyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		logger.Log.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	execution, err := h.strategyService.ExecuteStrategy(c.Request.Context(), &req)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to execute strategy")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to execute strategy", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":   "Strategy executed successfully",
		"execution": execution,
	})
}

// GetVault handles GET /api/v1/vaults/:id
func (h *StrategyHandler) GetVault(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vault ID"})
		return
	}

	vault, err := h.strategyService.GetVault(id)
	if err != nil {
		logger.Log.WithError(err).WithField("vault_id", id).Error("Failed to get vault")
		c.JSON(http.StatusNotFound, gin.H{"error": "Vault not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"vault": vault})
}

// ListVaults handles GET /api/v1/vaults
func (h *StrategyHandler) ListVaults(c *gin.Context) {
	limitStr := c.DefaultQuery("limit", "10")
	offsetStr := c.DefaultQuery("offset", "0")

	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 {
		limit = 10
	}

	offset, err := strconv.Atoi(offsetStr)
	if err != nil || offset < 0 {
		offset = 0
	}

	vaults, err := h.strategyService.ListVaults(limit, offset)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to list vaults")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list vaults"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"vaults": vaults,
		"limit":  limit,
		"offset": offset,
	})
}

// GetExecution handles GET /api/v1/executions/:id
func (h *StrategyHandler) GetExecution(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid execution ID"})
		return
	}

	execution, err := h.strategyService.GetExecution(id)
	if err != nil {
		logger.Log.WithError(err).WithField("execution_id", id).Error("Failed to get execution")
		c.JSON(http.StatusNotFound, gin.H{"error": "Execution not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"execution": execution})
}

// ListExecutions handles GET /api/v1/executions
func (h *StrategyHandler) ListExecutions(c *gin.Context) {
	limitStr := c.DefaultQuery("limit", "10")
	offsetStr := c.DefaultQuery("offset", "0")

	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 {
		limit = 10
	}

	offset, err := strconv.Atoi(offsetStr)
	if err != nil || offset < 0 {
		offset = 0
	}

	executions, err := h.strategyService.ListExecutions(limit, offset)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to list executions")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list executions"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"executions": executions,
		"limit":      limit,
		"offset":     offset,
	})
}

// WithdrawAllInvestments handles POST /api/v1/vaults/:id/withdraw-all
func (h *StrategyHandler) WithdrawAllInvestments(c *gin.Context) {
	idStr := c.Param("id")
	vaultID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vault ID"})
		return
	}

	execution, err := h.strategyService.WithdrawAllInvestments(c.Request.Context(), vaultID)
	if err != nil {
		logger.Log.WithError(err).WithField("vault_id", vaultID).Error("Failed to withdraw all investments")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to withdraw all investments", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":   "All investments withdrawn successfully",
		"execution": execution,
	})
}
