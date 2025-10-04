package server

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"ai-vault-backend/internal/blockchain"
	"ai-vault-backend/internal/config"
	"ai-vault-backend/internal/handlers"
	"ai-vault-backend/internal/logger"
	"ai-vault-backend/internal/services"

	"github.com/gin-gonic/gin"
)

// Server represents the HTTP server
type Server struct {
	cfg  *config.Config
	http *http.Server
}

// New creates a new server instance
func New(cfg *config.Config) *Server {
	return &Server{
		cfg: cfg,
	}
}

// Start starts the HTTP server
func (s *Server) Start() error {
	// Initialize blockchain client
	blockchainClient, err := blockchain.NewClient(s.cfg.Blockchain)
	if err != nil {
		return fmt.Errorf("failed to initialize blockchain client: %w", err)
	}

	// Initialize contract service
	contractService, err := blockchain.NewContractService(blockchainClient, s.cfg.Blockchain)
	if err != nil {
		return fmt.Errorf("failed to initialize contract service: %w", err)
	}

	// Initialize services
	vaultService := services.NewVaultService(contractService)

	// Initialize handlers
	vaultHandler := handlers.NewVaultHandler(vaultService)

	// Setup routes
	router := s.setupRoutes(vaultHandler)

	// Create HTTP server
	s.http = &http.Server{
		Addr:         ":" + s.cfg.Server.Port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	logger.Log.WithField("port", s.cfg.Server.Port).Info("Starting server")

	// Start server
	if err := s.http.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		return fmt.Errorf("failed to start server: %w", err)
	}

	return nil
}

// Stop stops the HTTP server gracefully
func (s *Server) Stop(ctx context.Context) error {
	logger.Log.Info("Stopping server")
	return s.http.Shutdown(ctx)
}

// setupRoutes configures all API routes
func (s *Server) setupRoutes(vaultHandler *handlers.VaultHandler) *gin.Engine {
	// Set Gin mode
	if s.cfg.LogLevel == "debug" {
		gin.SetMode(gin.DebugMode)
	} else {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()

	// Middleware
	router.Use(gin.Logger())
	router.Use(gin.Recovery())
	router.Use(corsMiddleware())

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "healthy",
			"timestamp": time.Now().Unix(),
			"version":   "1.0.0",
		})
	})

	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		// Vault allocation management
		v1.POST("/allocations", vaultHandler.UpdateAllocations)
		v1.POST("/withdraw", vaultHandler.WithdrawAllInvestments)

		// Adapter configuration
		adapters := v1.Group("/adapters")
		{
			// Aave adapter
			adapters.POST("/aave/configure", vaultHandler.ConfigureAaveAdapter)

			// UniswapV2 adapter
			adapters.POST("/uniswapv2/configure", vaultHandler.ConfigureUniswapV2Adapter)
			adapters.POST("/uniswapv2/slippage", vaultHandler.UpdateUniswapV2Slippage)
			adapters.POST("/uniswapv2/update", vaultHandler.UpdateUniswapV2Config)

			// UniswapV3 adapter
			adapters.POST("/uniswapv3/configure", vaultHandler.ConfigureUniswapV3Adapter)
			adapters.POST("/uniswapv3/slippage", vaultHandler.UpdateUniswapV3Slippage)
			adapters.POST("/uniswapv3/update", vaultHandler.UpdateUniswapV3Config)
		}
	}

	return router
}

// corsMiddleware adds CORS headers
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Accept, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}
