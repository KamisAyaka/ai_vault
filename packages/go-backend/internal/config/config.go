package config

import (
	"os"

	"github.com/joho/godotenv"
)

// Config holds all configuration for our application
type Config struct {
	Server     ServerConfig
	Blockchain BlockchainConfig
	LogLevel   string
}

// ServerConfig holds server configuration
type ServerConfig struct {
	Port string
}

// BlockchainConfig holds blockchain configuration
type BlockchainConfig struct {
	RPCURL              string
	PrivateKey          string
	VaultManagerAddress string
}

// Load loads configuration from environment variables
func Load() (*Config, error) {
	// Load .env file if it exists
	_ = godotenv.Load()

	cfg := &Config{
		Server: ServerConfig{
			Port: getEnv("SERVER_PORT", "8080"),
		},
		Blockchain: BlockchainConfig{
			RPCURL:              getEnv("ETH_RPC_URL", "http://localhost:8545"),
			PrivateKey:          getEnv("PRIVATE_KEY", ""),
			VaultManagerAddress: getEnv("VAULT_MANAGER_ADDRESS", ""),
		},
		LogLevel: getEnv("LOG_LEVEL", "info"),
	}

	return cfg, nil
}

// getEnv gets an environment variable with a fallback default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
