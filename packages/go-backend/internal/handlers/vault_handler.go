package handlers

import (
	"net/http"

	"ai-vault-backend/internal/logger"
	"ai-vault-backend/internal/services"

	"github.com/gin-gonic/gin"
)

// VaultHandler handles vault-related HTTP requests
type VaultHandler struct {
	vaultService *services.VaultService
}

// NewVaultHandler creates a new vault handler
func NewVaultHandler(vaultService *services.VaultService) *VaultHandler {
	return &VaultHandler{
		vaultService: vaultService,
	}
}

// UpdateAllocations handles POST /api/v1/allocations
func (h *VaultHandler) UpdateAllocations(c *gin.Context) {
	var req services.UpdateAllocationsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		logger.Log.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	response, err := h.vaultService.UpdateAllocations(c.Request.Context(), &req)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to update allocations")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update allocations", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Allocations updated successfully",
		"result":  response,
	})
}

// WithdrawAllInvestments handles POST /api/v1/withdraw
func (h *VaultHandler) WithdrawAllInvestments(c *gin.Context) {
	var req services.WithdrawAllInvestmentsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		logger.Log.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	response, err := h.vaultService.WithdrawAllInvestments(c.Request.Context(), &req)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to withdraw all investments")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to withdraw all investments", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "All investments withdrawn successfully",
		"result":  response,
	})
}

/*//////////////////////////////////////////////////////////////
                    ADAPTER CONFIGURATION HANDLERS
//////////////////////////////////////////////////////////////*/

// ConfigureAaveAdapter handles POST /api/v1/adapters/aave/configure
func (h *VaultHandler) ConfigureAaveAdapter(c *gin.Context) {
	var req services.ConfigureAaveAdapterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		logger.Log.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	response, err := h.vaultService.ConfigureAaveAdapter(c.Request.Context(), &req)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to configure Aave adapter")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to configure Aave adapter", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Aave adapter configured successfully",
		"result":  response,
	})
}

// ConfigureUniswapV2Adapter handles POST /api/v1/adapters/uniswapv2/configure
func (h *VaultHandler) ConfigureUniswapV2Adapter(c *gin.Context) {
	var req services.ConfigureUniswapV2AdapterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		logger.Log.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	response, err := h.vaultService.ConfigureUniswapV2Adapter(c.Request.Context(), &req)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to configure UniswapV2 adapter")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to configure UniswapV2 adapter", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "UniswapV2 adapter configured successfully",
		"result":  response,
	})
}

// UpdateUniswapV2Slippage handles POST /api/v1/adapters/uniswapv2/slippage
func (h *VaultHandler) UpdateUniswapV2Slippage(c *gin.Context) {
	var req services.UpdateUniswapV2SlippageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		logger.Log.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	response, err := h.vaultService.UpdateUniswapV2Slippage(c.Request.Context(), &req)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to update UniswapV2 slippage")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update UniswapV2 slippage", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "UniswapV2 slippage updated successfully",
		"result":  response,
	})
}

// UpdateUniswapV2Config handles POST /api/v1/adapters/uniswapv2/update
func (h *VaultHandler) UpdateUniswapV2Config(c *gin.Context) {
	var req services.UpdateUniswapV2ConfigRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		logger.Log.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	response, err := h.vaultService.UpdateUniswapV2Config(c.Request.Context(), &req)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to update UniswapV2 config")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update UniswapV2 config", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "UniswapV2 config updated successfully",
		"result":  response,
	})
}

// ConfigureUniswapV3Adapter handles POST /api/v1/adapters/uniswapv3/configure
func (h *VaultHandler) ConfigureUniswapV3Adapter(c *gin.Context) {
	var req services.ConfigureUniswapV3AdapterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		logger.Log.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	response, err := h.vaultService.ConfigureUniswapV3Adapter(c.Request.Context(), &req)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to configure UniswapV3 adapter")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to configure UniswapV3 adapter", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "UniswapV3 adapter configured successfully",
		"result":  response,
	})
}

// UpdateUniswapV3Slippage handles POST /api/v1/adapters/uniswapv3/slippage
func (h *VaultHandler) UpdateUniswapV3Slippage(c *gin.Context) {
	var req services.UpdateUniswapV3SlippageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		logger.Log.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	response, err := h.vaultService.UpdateUniswapV3Slippage(c.Request.Context(), &req)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to update UniswapV3 slippage")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update UniswapV3 slippage", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "UniswapV3 slippage updated successfully",
		"result":  response,
	})
}

// UpdateUniswapV3Config handles POST /api/v1/adapters/uniswapv3/update
func (h *VaultHandler) UpdateUniswapV3Config(c *gin.Context) {
	var req services.UpdateUniswapV3ConfigRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		logger.Log.WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	response, err := h.vaultService.UpdateUniswapV3Config(c.Request.Context(), &req)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to update UniswapV3 config")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update UniswapV3 config", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "UniswapV3 config updated successfully",
		"result":  response,
	})
}
