package blockchain

import (
	"context"
	"crypto/ecdsa"
	"math/big"

	"ai-vault-backend/internal/config"
	"ai-vault-backend/internal/logger"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/sirupsen/logrus"
)

// Client wraps the Ethereum client with additional functionality
type Client struct {
	client      *ethclient.Client
	privateKey  *ecdsa.PrivateKey
	chainID     *big.Int
	maxGasLimit uint64
}

// NewClient creates a new blockchain client
func NewClient(cfg config.BlockchainConfig) (*Client, error) {
	client, err := ethclient.Dial(cfg.RPCURL)
	if err != nil {
		return nil, err
	}

	// Parse private key
	privateKey, err := crypto.HexToECDSA(cfg.PrivateKey)
	if err != nil {
		return nil, err
	}

	// Get chain ID
	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		return nil, err
	}

	return &Client{
		client:      client,
		privateKey:  privateKey,
		chainID:     chainID,
		maxGasLimit: cfg.MaxGasLimit,
	}, nil
}

// GetAddress returns the address of the configured private key
func (c *Client) GetAddress() common.Address {
	return crypto.PubkeyToAddress(c.privateKey.PublicKey)
}

// GetTransactOpts returns the transaction options for sending transactions
func (c *Client) GetTransactOpts(ctx context.Context) (*bind.TransactOpts, error) {
	nonce, err := c.client.PendingNonceAt(ctx, c.GetAddress())
	if err != nil {
		return nil, err
	}

	gasPrice, err := c.client.SuggestGasPrice(ctx)
	if err != nil {
		return nil, err
	}

	auth, err := bind.NewKeyedTransactorWithChainID(c.privateKey, c.chainID)
	if err != nil {
		return nil, err
	}

	auth.Nonce = big.NewInt(int64(nonce))
	auth.Value = big.NewInt(0)
	auth.GasLimit = c.maxGasLimit // Use configured max gas limit
	auth.GasPrice = gasPrice
	auth.Context = ctx

	return auth, nil
}

// GetBalance returns the ETH balance of the configured address
func (c *Client) GetBalance(ctx context.Context) (*big.Int, error) {
	return c.client.BalanceAt(ctx, c.GetAddress(), nil)
}

// GetTokenBalance returns the token balance of the configured address
func (c *Client) GetTokenBalance(ctx context.Context, tokenAddress common.Address) (*big.Int, error) {
	// ERC20 balanceOf function signature
	balanceOfData := []byte{0x70, 0xa0, 0x82, 0x31}
	addressData := common.LeftPadBytes(c.GetAddress().Bytes(), 32)
	data := append(balanceOfData, addressData...)

	msg := ethereum.CallMsg{
		To:   &tokenAddress,
		Data: data,
	}

	result, err := c.client.CallContract(ctx, msg, nil)
	if err != nil {
		return nil, err
	}

	return new(big.Int).SetBytes(result), nil
}

// SendTransaction sends a transaction to the blockchain
func (c *Client) SendTransaction(ctx context.Context, to common.Address, value *big.Int, data []byte) (*types.Transaction, error) {
	// Get nonce
	nonce, err := c.client.PendingNonceAt(ctx, c.GetAddress())
	if err != nil {
		return nil, err
	}

	// Get gas price
	gasPrice, err := c.client.SuggestGasPrice(ctx)
	if err != nil {
		return nil, err
	}

	// Estimate gas limit
	estimatedGas, err := c.client.EstimateGas(ctx, ethereum.CallMsg{
		From:  c.GetAddress(),
		To:    &to,
		Value: value,
		Data:  data,
	})
	if err != nil {
		return nil, err
	}
	
	// Set gas limit with reasonable maximum for Sepolia
	gasLimit := estimatedGas
	if gasLimit > c.maxGasLimit {
		gasLimit = c.maxGasLimit // Cap at configured max gas limit
	}

	// Create transaction
	tx := types.NewTransaction(nonce, to, value, gasLimit, gasPrice, data)

	// Sign transaction
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(c.chainID), c.privateKey)
	if err != nil {
		return nil, err
	}

	// Send transaction
	err = c.client.SendTransaction(ctx, signedTx)
	if err != nil {
		return nil, err
	}

	logger.Log.WithFields(logrus.Fields{
		"tx_hash": signedTx.Hash().Hex(),
		"to":      to.Hex(),
		"value":   value.String(),
		"gas":     gasLimit,
	}).Info("Transaction sent")

	return signedTx, nil
}

// WaitForTransaction waits for a transaction to be confirmed
func (c *Client) WaitForTransaction(ctx context.Context, txHash common.Hash) (*types.Receipt, error) {
	return c.client.TransactionReceipt(ctx, txHash)
}

// GetClient returns the underlying Ethereum client
func (c *Client) GetClient() *ethclient.Client {
	return c.client
}
