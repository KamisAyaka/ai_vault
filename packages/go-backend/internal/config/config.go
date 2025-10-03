package config

import (
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

// Config holds all configuration for our application
type Config struct {
	Server     ServerConfig
	Database   DatabaseConfig
	Blockchain BlockchainConfig
	LogLevel   string
}

// ServerConfig holds server configuration
type ServerConfig struct {
	Port string
}

// DatabaseConfig holds database configuration
type DatabaseConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	DBName   string
}

// BlockchainConfig holds blockchain configuration
type BlockchainConfig struct {
	RPCURL              string
	PrivateKey          string
	VaultManagerAddress string
	WETHAddress         string
	USDCAddress         string
	DAIAddress          string
}

// Load loads configuration from environment variables
func Load() (*Config, error) {
	// Load .env file if it exists
	_ = godotenv.Load()

	cfg := &Config{
		Server: ServerConfig{
			Port: getEnv("SERVER_PORT", "8080"),
		},
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnvAsInt("DB_PORT", 5432),
			User:     getEnv("DB_USER", "ai_vault"),
			Password: getEnv("DB_PASSWORD", ""),
			DBName:   getEnv("DB_NAME", "ai_vault"),
		},
		Blockchain: BlockchainConfig{
			RPCURL:              getEnv("ETH_RPC_URL", "http://localhost:8545"),
			PrivateKey:          getEnv("PRIVATE_KEY", ""),
			VaultManagerAddress: getEnv("VAULT_MANAGER_ADDRESS", ""),
			WETHAddress:         getEnv("WETH_ADDRESS", ""),
			USDCAddress:         getEnv("USDC_ADDRESS", ""),
			DAIAddress:          getEnv("DAI_ADDRESS", ""),
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

// getEnvAsInt gets an environment variable as integer with a fallback default value
func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}
