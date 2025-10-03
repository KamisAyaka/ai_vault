package database

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Strategy represents an AI-generated investment strategy
type Strategy struct {
	ID          uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name        string    `gorm:"not null" json:"name"`
	Description string    `json:"description"`
	// AI-generated strategy parameters
	Allocations []Allocation `gorm:"foreignKey:StrategyID" json:"allocations"`
	// Execution status
	Status      string    `gorm:"default:'pending'" json:"status"` // pending, executing, completed, failed
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
	ExecutedAt  *time.Time `json:"executed_at,omitempty"`
}

// Allocation represents a specific allocation within a strategy
type Allocation struct {
	ID           uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	StrategyID   uuid.UUID `gorm:"type:uuid;not null" json:"strategy_id"`
	AdapterIndex int       `gorm:"not null" json:"adapter_index"` // Index in the vault manager's adapter list
	Percentage   int       `gorm:"not null" json:"percentage"`    // Allocation percentage (0-1000 for precision)
	Protocol     string    `gorm:"not null" json:"protocol"`      // Protocol name (Aave, UniswapV2, UniswapV3)
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// Vault represents a vault in the system
type Vault struct {
	ID           uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Address      string    `gorm:"unique;not null" json:"address"`
	TokenAddress string    `gorm:"not null" json:"token_address"`
	TokenSymbol  string    `gorm:"not null" json:"token_symbol"`
	TokenName    string    `gorm:"not null" json:"token_name"`
	IsActive     bool      `gorm:"default:true" json:"is_active"`
	TotalAssets  string    `gorm:"type:numeric" json:"total_assets"` // Using string for precision
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// Execution represents the execution of a strategy
type Execution struct {
	ID         uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	StrategyID uuid.UUID `gorm:"type:uuid;not null" json:"strategy_id"`
	VaultID    uuid.UUID `gorm:"type:uuid;not null" json:"vault_id"`
	Strategy   Strategy  `gorm:"foreignKey:StrategyID" json:"strategy"`
	Vault      Vault     `gorm:"foreignKey:VaultID" json:"vault"`
	// Execution details
	Status       string    `gorm:"default:'pending'" json:"status"` // pending, executing, completed, failed
	TxHash       string    `json:"tx_hash,omitempty"`
	GasUsed      uint64    `json:"gas_used,omitempty"`
	GasPrice     string    `gorm:"type:numeric" json:"gas_price,omitempty"`
	Error        string    `json:"error,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
	CompletedAt  *time.Time `json:"completed_at,omitempty"`
}

// Transaction represents a blockchain transaction
type Transaction struct {
	ID          uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	ExecutionID uuid.UUID `gorm:"type:uuid;not null" json:"execution_id"`
	Execution   Execution `gorm:"foreignKey:ExecutionID" json:"execution"`
	TxHash      string    `gorm:"unique;not null" json:"tx_hash"`
	From        string    `gorm:"not null" json:"from"`
	To          string    `gorm:"not null" json:"to"`
	Value       string    `gorm:"type:numeric" json:"value"`
	GasUsed     uint64    `json:"gas_used"`
	GasPrice    string    `gorm:"type:numeric" json:"gas_price"`
	Status      string    `gorm:"not null" json:"status"` // pending, confirmed, failed
	BlockNumber uint64    `json:"block_number,omitempty"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// BeforeCreate hooks for GORM
func (s *Strategy) BeforeCreate(tx *gorm.DB) error {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return nil
}

func (a *Allocation) BeforeCreate(tx *gorm.DB) error {
	if a.ID == uuid.Nil {
		a.ID = uuid.New()
	}
	return nil
}

func (v *Vault) BeforeCreate(tx *gorm.DB) error {
	if v.ID == uuid.Nil {
		v.ID = uuid.New()
	}
	return nil
}

func (e *Execution) BeforeCreate(tx *gorm.DB) error {
	if e.ID == uuid.Nil {
		e.ID = uuid.New()
	}
	return nil
}

func (t *Transaction) BeforeCreate(tx *gorm.DB) error {
	if t.ID == uuid.Nil {
		t.ID = uuid.New()
	}
	return nil
}
