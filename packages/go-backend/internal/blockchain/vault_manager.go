// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package blockchain

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// VaultManagerMetaData contains all meta data concerning the VaultManager contract.
var VaultManagerMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addAdapter\",\"inputs\":[{\"name\":\"adapter\",\"type\":\"address\",\"internalType\":\"contractIProtocolAdapter\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addVault\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"contractIERC20\"},{\"name\":\"vaultAddress\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"execute\",\"inputs\":[{\"name\":\"adapterIndex\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeBatch\",\"inputs\":[{\"name\":\"adapterIndices\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"data\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getAllAdapters\",\"inputs\":[],\"outputs\":[{\"name\":\"adapters\",\"type\":\"address[]\",\"internalType\":\"contractIProtocolAdapter[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isAdapterApproved\",\"inputs\":[{\"name\":\"adapter\",\"type\":\"address\",\"internalType\":\"contractIProtocolAdapter\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"partialUpdateHoldingAllocation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"contractIERC20\"},{\"name\":\"divestAdapterIndices\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"divestAmounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"investAdapterIndices\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"investAmounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"investAllocations\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setVaultNotActive\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"contractIERC20\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updateHoldingAllocation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"contractIERC20\"},{\"name\":\"adapterIndices\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"allocationData\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"withdrawAllInvestments\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"contractIERC20\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"AdapterAddedToList\",\"inputs\":[{\"name\":\"adapter\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"contractIProtocolAdapter\"},{\"name\":\"adapterName\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"VaultCreatedAndRegistered\",\"inputs\":[{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"vaultName\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AIAgentVaultManager__AdapterAlreadyApproved\",\"inputs\":[{\"name\":\"adapter\",\"type\":\"address\",\"internalType\":\"contractIProtocolAdapter\"}]},{\"type\":\"error\",\"name\":\"AIAgentVaultManager__AdapterCallFailed\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AIAgentVaultManager__AdapterNotApproved\",\"inputs\":[{\"name\":\"adapter\",\"type\":\"address\",\"internalType\":\"contractIProtocolAdapter\"}]},{\"type\":\"error\",\"name\":\"AIAgentVaultManager__BatchLengthMismatch\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AIAgentVaultManager__InvalidAdapterIndex\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"AIAgentVaultManager__InvalidAllocation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AIAgentVaultManager__VaultNotRegistered\",\"inputs\":[{\"name\":\"vault\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]}]",
}

// VaultManagerABI is the input ABI used to generate the binding from.
// Deprecated: Use VaultManagerMetaData.ABI instead.
var VaultManagerABI = VaultManagerMetaData.ABI

// VaultManager is an auto generated Go binding around an Ethereum contract.
type VaultManager struct {
	VaultManagerCaller     // Read-only binding to the contract
	VaultManagerTransactor // Write-only binding to the contract
	VaultManagerFilterer   // Log filterer for contract events
}

// VaultManagerCaller is an auto generated read-only Go binding around an Ethereum contract.
type VaultManagerCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// VaultManagerTransactor is an auto generated write-only Go binding around an Ethereum contract.
type VaultManagerTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// VaultManagerFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type VaultManagerFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// VaultManagerSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type VaultManagerSession struct {
	Contract     *VaultManager     // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// VaultManagerCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type VaultManagerCallerSession struct {
	Contract *VaultManagerCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts       // Call options to use throughout this session
}

// VaultManagerTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type VaultManagerTransactorSession struct {
	Contract     *VaultManagerTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts       // Transaction auth options to use throughout this session
}

// VaultManagerRaw is an auto generated low-level Go binding around an Ethereum contract.
type VaultManagerRaw struct {
	Contract *VaultManager // Generic contract binding to access the raw methods on
}

// VaultManagerCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type VaultManagerCallerRaw struct {
	Contract *VaultManagerCaller // Generic read-only contract binding to access the raw methods on
}

// VaultManagerTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type VaultManagerTransactorRaw struct {
	Contract *VaultManagerTransactor // Generic write-only contract binding to access the raw methods on
}

// NewVaultManager creates a new instance of VaultManager, bound to a specific deployed contract.
func NewVaultManager(address common.Address, backend bind.ContractBackend) (*VaultManager, error) {
	contract, err := bindVaultManager(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &VaultManager{VaultManagerCaller: VaultManagerCaller{contract: contract}, VaultManagerTransactor: VaultManagerTransactor{contract: contract}, VaultManagerFilterer: VaultManagerFilterer{contract: contract}}, nil
}

// NewVaultManagerCaller creates a new read-only instance of VaultManager, bound to a specific deployed contract.
func NewVaultManagerCaller(address common.Address, caller bind.ContractCaller) (*VaultManagerCaller, error) {
	contract, err := bindVaultManager(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &VaultManagerCaller{contract: contract}, nil
}

// NewVaultManagerTransactor creates a new write-only instance of VaultManager, bound to a specific deployed contract.
func NewVaultManagerTransactor(address common.Address, transactor bind.ContractTransactor) (*VaultManagerTransactor, error) {
	contract, err := bindVaultManager(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &VaultManagerTransactor{contract: contract}, nil
}

// NewVaultManagerFilterer creates a new log filterer instance of VaultManager, bound to a specific deployed contract.
func NewVaultManagerFilterer(address common.Address, filterer bind.ContractFilterer) (*VaultManagerFilterer, error) {
	contract, err := bindVaultManager(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &VaultManagerFilterer{contract: contract}, nil
}

// bindVaultManager binds a generic wrapper to an already deployed contract.
func bindVaultManager(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := VaultManagerMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_VaultManager *VaultManagerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _VaultManager.Contract.VaultManagerCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_VaultManager *VaultManagerRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _VaultManager.Contract.VaultManagerTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_VaultManager *VaultManagerRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _VaultManager.Contract.VaultManagerTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_VaultManager *VaultManagerCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _VaultManager.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_VaultManager *VaultManagerTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _VaultManager.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_VaultManager *VaultManagerTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _VaultManager.Contract.contract.Transact(opts, method, params...)
}

// GetAllAdapters is a free data retrieval call binding the contract method 0xe31ada97.
//
// Solidity: function getAllAdapters() view returns(address[] adapters)
func (_VaultManager *VaultManagerCaller) GetAllAdapters(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _VaultManager.contract.Call(opts, &out, "getAllAdapters")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAllAdapters is a free data retrieval call binding the contract method 0xe31ada97.
//
// Solidity: function getAllAdapters() view returns(address[] adapters)
func (_VaultManager *VaultManagerSession) GetAllAdapters() ([]common.Address, error) {
	return _VaultManager.Contract.GetAllAdapters(&_VaultManager.CallOpts)
}

// GetAllAdapters is a free data retrieval call binding the contract method 0xe31ada97.
//
// Solidity: function getAllAdapters() view returns(address[] adapters)
func (_VaultManager *VaultManagerCallerSession) GetAllAdapters() ([]common.Address, error) {
	return _VaultManager.Contract.GetAllAdapters(&_VaultManager.CallOpts)
}

// IsAdapterApproved is a free data retrieval call binding the contract method 0x76cba77d.
//
// Solidity: function isAdapterApproved(address adapter) view returns(bool)
func (_VaultManager *VaultManagerCaller) IsAdapterApproved(opts *bind.CallOpts, adapter common.Address) (bool, error) {
	var out []interface{}
	err := _VaultManager.contract.Call(opts, &out, "isAdapterApproved", adapter)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsAdapterApproved is a free data retrieval call binding the contract method 0x76cba77d.
//
// Solidity: function isAdapterApproved(address adapter) view returns(bool)
func (_VaultManager *VaultManagerSession) IsAdapterApproved(adapter common.Address) (bool, error) {
	return _VaultManager.Contract.IsAdapterApproved(&_VaultManager.CallOpts, adapter)
}

// IsAdapterApproved is a free data retrieval call binding the contract method 0x76cba77d.
//
// Solidity: function isAdapterApproved(address adapter) view returns(bool)
func (_VaultManager *VaultManagerCallerSession) IsAdapterApproved(adapter common.Address) (bool, error) {
	return _VaultManager.Contract.IsAdapterApproved(&_VaultManager.CallOpts, adapter)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_VaultManager *VaultManagerCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _VaultManager.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_VaultManager *VaultManagerSession) Owner() (common.Address, error) {
	return _VaultManager.Contract.Owner(&_VaultManager.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_VaultManager *VaultManagerCallerSession) Owner() (common.Address, error) {
	return _VaultManager.Contract.Owner(&_VaultManager.CallOpts)
}

// AddAdapter is a paid mutator transaction binding the contract method 0x60d54d41.
//
// Solidity: function addAdapter(address adapter) returns()
func (_VaultManager *VaultManagerTransactor) AddAdapter(opts *bind.TransactOpts, adapter common.Address) (*types.Transaction, error) {
	return _VaultManager.contract.Transact(opts, "addAdapter", adapter)
}

// AddAdapter is a paid mutator transaction binding the contract method 0x60d54d41.
//
// Solidity: function addAdapter(address adapter) returns()
func (_VaultManager *VaultManagerSession) AddAdapter(adapter common.Address) (*types.Transaction, error) {
	return _VaultManager.Contract.AddAdapter(&_VaultManager.TransactOpts, adapter)
}

// AddAdapter is a paid mutator transaction binding the contract method 0x60d54d41.
//
// Solidity: function addAdapter(address adapter) returns()
func (_VaultManager *VaultManagerTransactorSession) AddAdapter(adapter common.Address) (*types.Transaction, error) {
	return _VaultManager.Contract.AddAdapter(&_VaultManager.TransactOpts, adapter)
}

// AddVault is a paid mutator transaction binding the contract method 0xec3a7823.
//
// Solidity: function addVault(address token, address vaultAddress) returns()
func (_VaultManager *VaultManagerTransactor) AddVault(opts *bind.TransactOpts, token common.Address, vaultAddress common.Address) (*types.Transaction, error) {
	return _VaultManager.contract.Transact(opts, "addVault", token, vaultAddress)
}

// AddVault is a paid mutator transaction binding the contract method 0xec3a7823.
//
// Solidity: function addVault(address token, address vaultAddress) returns()
func (_VaultManager *VaultManagerSession) AddVault(token common.Address, vaultAddress common.Address) (*types.Transaction, error) {
	return _VaultManager.Contract.AddVault(&_VaultManager.TransactOpts, token, vaultAddress)
}

// AddVault is a paid mutator transaction binding the contract method 0xec3a7823.
//
// Solidity: function addVault(address token, address vaultAddress) returns()
func (_VaultManager *VaultManagerTransactorSession) AddVault(token common.Address, vaultAddress common.Address) (*types.Transaction, error) {
	return _VaultManager.Contract.AddVault(&_VaultManager.TransactOpts, token, vaultAddress)
}

// Execute is a paid mutator transaction binding the contract method 0xff72ccf1.
//
// Solidity: function execute(uint256 adapterIndex, uint256 value, bytes data) returns()
func (_VaultManager *VaultManagerTransactor) Execute(opts *bind.TransactOpts, adapterIndex *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _VaultManager.contract.Transact(opts, "execute", adapterIndex, value, data)
}

// Execute is a paid mutator transaction binding the contract method 0xff72ccf1.
//
// Solidity: function execute(uint256 adapterIndex, uint256 value, bytes data) returns()
func (_VaultManager *VaultManagerSession) Execute(adapterIndex *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _VaultManager.Contract.Execute(&_VaultManager.TransactOpts, adapterIndex, value, data)
}

// Execute is a paid mutator transaction binding the contract method 0xff72ccf1.
//
// Solidity: function execute(uint256 adapterIndex, uint256 value, bytes data) returns()
func (_VaultManager *VaultManagerTransactorSession) Execute(adapterIndex *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _VaultManager.Contract.Execute(&_VaultManager.TransactOpts, adapterIndex, value, data)
}

// ExecuteBatch is a paid mutator transaction binding the contract method 0x32766caa.
//
// Solidity: function executeBatch(uint256[] adapterIndices, uint256[] values, bytes[] data) returns()
func (_VaultManager *VaultManagerTransactor) ExecuteBatch(opts *bind.TransactOpts, adapterIndices []*big.Int, values []*big.Int, data [][]byte) (*types.Transaction, error) {
	return _VaultManager.contract.Transact(opts, "executeBatch", adapterIndices, values, data)
}

// ExecuteBatch is a paid mutator transaction binding the contract method 0x32766caa.
//
// Solidity: function executeBatch(uint256[] adapterIndices, uint256[] values, bytes[] data) returns()
func (_VaultManager *VaultManagerSession) ExecuteBatch(adapterIndices []*big.Int, values []*big.Int, data [][]byte) (*types.Transaction, error) {
	return _VaultManager.Contract.ExecuteBatch(&_VaultManager.TransactOpts, adapterIndices, values, data)
}

// ExecuteBatch is a paid mutator transaction binding the contract method 0x32766caa.
//
// Solidity: function executeBatch(uint256[] adapterIndices, uint256[] values, bytes[] data) returns()
func (_VaultManager *VaultManagerTransactorSession) ExecuteBatch(adapterIndices []*big.Int, values []*big.Int, data [][]byte) (*types.Transaction, error) {
	return _VaultManager.Contract.ExecuteBatch(&_VaultManager.TransactOpts, adapterIndices, values, data)
}

// PartialUpdateHoldingAllocation is a paid mutator transaction binding the contract method 0xa0a9bb07.
//
// Solidity: function partialUpdateHoldingAllocation(address token, uint256[] divestAdapterIndices, uint256[] divestAmounts, uint256[] investAdapterIndices, uint256[] investAmounts, uint256[] investAllocations) returns()
func (_VaultManager *VaultManagerTransactor) PartialUpdateHoldingAllocation(opts *bind.TransactOpts, token common.Address, divestAdapterIndices []*big.Int, divestAmounts []*big.Int, investAdapterIndices []*big.Int, investAmounts []*big.Int, investAllocations []*big.Int) (*types.Transaction, error) {
	return _VaultManager.contract.Transact(opts, "partialUpdateHoldingAllocation", token, divestAdapterIndices, divestAmounts, investAdapterIndices, investAmounts, investAllocations)
}

// PartialUpdateHoldingAllocation is a paid mutator transaction binding the contract method 0xa0a9bb07.
//
// Solidity: function partialUpdateHoldingAllocation(address token, uint256[] divestAdapterIndices, uint256[] divestAmounts, uint256[] investAdapterIndices, uint256[] investAmounts, uint256[] investAllocations) returns()
func (_VaultManager *VaultManagerSession) PartialUpdateHoldingAllocation(token common.Address, divestAdapterIndices []*big.Int, divestAmounts []*big.Int, investAdapterIndices []*big.Int, investAmounts []*big.Int, investAllocations []*big.Int) (*types.Transaction, error) {
	return _VaultManager.Contract.PartialUpdateHoldingAllocation(&_VaultManager.TransactOpts, token, divestAdapterIndices, divestAmounts, investAdapterIndices, investAmounts, investAllocations)
}

// PartialUpdateHoldingAllocation is a paid mutator transaction binding the contract method 0xa0a9bb07.
//
// Solidity: function partialUpdateHoldingAllocation(address token, uint256[] divestAdapterIndices, uint256[] divestAmounts, uint256[] investAdapterIndices, uint256[] investAmounts, uint256[] investAllocations) returns()
func (_VaultManager *VaultManagerTransactorSession) PartialUpdateHoldingAllocation(token common.Address, divestAdapterIndices []*big.Int, divestAmounts []*big.Int, investAdapterIndices []*big.Int, investAmounts []*big.Int, investAllocations []*big.Int) (*types.Transaction, error) {
	return _VaultManager.Contract.PartialUpdateHoldingAllocation(&_VaultManager.TransactOpts, token, divestAdapterIndices, divestAmounts, investAdapterIndices, investAmounts, investAllocations)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_VaultManager *VaultManagerTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _VaultManager.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_VaultManager *VaultManagerSession) RenounceOwnership() (*types.Transaction, error) {
	return _VaultManager.Contract.RenounceOwnership(&_VaultManager.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_VaultManager *VaultManagerTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _VaultManager.Contract.RenounceOwnership(&_VaultManager.TransactOpts)
}

// SetVaultNotActive is a paid mutator transaction binding the contract method 0xfa4b4bbf.
//
// Solidity: function setVaultNotActive(address token) returns()
func (_VaultManager *VaultManagerTransactor) SetVaultNotActive(opts *bind.TransactOpts, token common.Address) (*types.Transaction, error) {
	return _VaultManager.contract.Transact(opts, "setVaultNotActive", token)
}

// SetVaultNotActive is a paid mutator transaction binding the contract method 0xfa4b4bbf.
//
// Solidity: function setVaultNotActive(address token) returns()
func (_VaultManager *VaultManagerSession) SetVaultNotActive(token common.Address) (*types.Transaction, error) {
	return _VaultManager.Contract.SetVaultNotActive(&_VaultManager.TransactOpts, token)
}

// SetVaultNotActive is a paid mutator transaction binding the contract method 0xfa4b4bbf.
//
// Solidity: function setVaultNotActive(address token) returns()
func (_VaultManager *VaultManagerTransactorSession) SetVaultNotActive(token common.Address) (*types.Transaction, error) {
	return _VaultManager.Contract.SetVaultNotActive(&_VaultManager.TransactOpts, token)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_VaultManager *VaultManagerTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _VaultManager.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_VaultManager *VaultManagerSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _VaultManager.Contract.TransferOwnership(&_VaultManager.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_VaultManager *VaultManagerTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _VaultManager.Contract.TransferOwnership(&_VaultManager.TransactOpts, newOwner)
}

// UpdateHoldingAllocation is a paid mutator transaction binding the contract method 0xd5282cab.
//
// Solidity: function updateHoldingAllocation(address token, uint256[] adapterIndices, uint256[] allocationData) returns()
func (_VaultManager *VaultManagerTransactor) UpdateHoldingAllocation(opts *bind.TransactOpts, token common.Address, adapterIndices []*big.Int, allocationData []*big.Int) (*types.Transaction, error) {
	return _VaultManager.contract.Transact(opts, "updateHoldingAllocation", token, adapterIndices, allocationData)
}

// UpdateHoldingAllocation is a paid mutator transaction binding the contract method 0xd5282cab.
//
// Solidity: function updateHoldingAllocation(address token, uint256[] adapterIndices, uint256[] allocationData) returns()
func (_VaultManager *VaultManagerSession) UpdateHoldingAllocation(token common.Address, adapterIndices []*big.Int, allocationData []*big.Int) (*types.Transaction, error) {
	return _VaultManager.Contract.UpdateHoldingAllocation(&_VaultManager.TransactOpts, token, adapterIndices, allocationData)
}

// UpdateHoldingAllocation is a paid mutator transaction binding the contract method 0xd5282cab.
//
// Solidity: function updateHoldingAllocation(address token, uint256[] adapterIndices, uint256[] allocationData) returns()
func (_VaultManager *VaultManagerTransactorSession) UpdateHoldingAllocation(token common.Address, adapterIndices []*big.Int, allocationData []*big.Int) (*types.Transaction, error) {
	return _VaultManager.Contract.UpdateHoldingAllocation(&_VaultManager.TransactOpts, token, adapterIndices, allocationData)
}

// WithdrawAllInvestments is a paid mutator transaction binding the contract method 0x588f658b.
//
// Solidity: function withdrawAllInvestments(address token) returns()
func (_VaultManager *VaultManagerTransactor) WithdrawAllInvestments(opts *bind.TransactOpts, token common.Address) (*types.Transaction, error) {
	return _VaultManager.contract.Transact(opts, "withdrawAllInvestments", token)
}

// WithdrawAllInvestments is a paid mutator transaction binding the contract method 0x588f658b.
//
// Solidity: function withdrawAllInvestments(address token) returns()
func (_VaultManager *VaultManagerSession) WithdrawAllInvestments(token common.Address) (*types.Transaction, error) {
	return _VaultManager.Contract.WithdrawAllInvestments(&_VaultManager.TransactOpts, token)
}

// WithdrawAllInvestments is a paid mutator transaction binding the contract method 0x588f658b.
//
// Solidity: function withdrawAllInvestments(address token) returns()
func (_VaultManager *VaultManagerTransactorSession) WithdrawAllInvestments(token common.Address) (*types.Transaction, error) {
	return _VaultManager.Contract.WithdrawAllInvestments(&_VaultManager.TransactOpts, token)
}

// VaultManagerAdapterAddedToListIterator is returned from FilterAdapterAddedToList and is used to iterate over the raw logs and unpacked data for AdapterAddedToList events raised by the VaultManager contract.
type VaultManagerAdapterAddedToListIterator struct {
	Event *VaultManagerAdapterAddedToList // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *VaultManagerAdapterAddedToListIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(VaultManagerAdapterAddedToList)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(VaultManagerAdapterAddedToList)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *VaultManagerAdapterAddedToListIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *VaultManagerAdapterAddedToListIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// VaultManagerAdapterAddedToList represents a AdapterAddedToList event raised by the VaultManager contract.
type VaultManagerAdapterAddedToList struct {
	Adapter     common.Address
	AdapterName string
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterAdapterAddedToList is a free log retrieval operation binding the contract event 0xe4e23196d7265020a12c07b0fd7f9ac5470e22c412d8a6cd7fc5efb26c0ee376.
//
// Solidity: event AdapterAddedToList(address indexed adapter, string adapterName)
func (_VaultManager *VaultManagerFilterer) FilterAdapterAddedToList(opts *bind.FilterOpts, adapter []common.Address) (*VaultManagerAdapterAddedToListIterator, error) {

	var adapterRule []interface{}
	for _, adapterItem := range adapter {
		adapterRule = append(adapterRule, adapterItem)
	}

	logs, sub, err := _VaultManager.contract.FilterLogs(opts, "AdapterAddedToList", adapterRule)
	if err != nil {
		return nil, err
	}
	return &VaultManagerAdapterAddedToListIterator{contract: _VaultManager.contract, event: "AdapterAddedToList", logs: logs, sub: sub}, nil
}

// WatchAdapterAddedToList is a free log subscription operation binding the contract event 0xe4e23196d7265020a12c07b0fd7f9ac5470e22c412d8a6cd7fc5efb26c0ee376.
//
// Solidity: event AdapterAddedToList(address indexed adapter, string adapterName)
func (_VaultManager *VaultManagerFilterer) WatchAdapterAddedToList(opts *bind.WatchOpts, sink chan<- *VaultManagerAdapterAddedToList, adapter []common.Address) (event.Subscription, error) {

	var adapterRule []interface{}
	for _, adapterItem := range adapter {
		adapterRule = append(adapterRule, adapterItem)
	}

	logs, sub, err := _VaultManager.contract.WatchLogs(opts, "AdapterAddedToList", adapterRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(VaultManagerAdapterAddedToList)
				if err := _VaultManager.contract.UnpackLog(event, "AdapterAddedToList", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseAdapterAddedToList is a log parse operation binding the contract event 0xe4e23196d7265020a12c07b0fd7f9ac5470e22c412d8a6cd7fc5efb26c0ee376.
//
// Solidity: event AdapterAddedToList(address indexed adapter, string adapterName)
func (_VaultManager *VaultManagerFilterer) ParseAdapterAddedToList(log types.Log) (*VaultManagerAdapterAddedToList, error) {
	event := new(VaultManagerAdapterAddedToList)
	if err := _VaultManager.contract.UnpackLog(event, "AdapterAddedToList", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// VaultManagerOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the VaultManager contract.
type VaultManagerOwnershipTransferredIterator struct {
	Event *VaultManagerOwnershipTransferred // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *VaultManagerOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(VaultManagerOwnershipTransferred)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(VaultManagerOwnershipTransferred)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *VaultManagerOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *VaultManagerOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// VaultManagerOwnershipTransferred represents a OwnershipTransferred event raised by the VaultManager contract.
type VaultManagerOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_VaultManager *VaultManagerFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*VaultManagerOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _VaultManager.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &VaultManagerOwnershipTransferredIterator{contract: _VaultManager.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_VaultManager *VaultManagerFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *VaultManagerOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _VaultManager.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(VaultManagerOwnershipTransferred)
				if err := _VaultManager.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseOwnershipTransferred is a log parse operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_VaultManager *VaultManagerFilterer) ParseOwnershipTransferred(log types.Log) (*VaultManagerOwnershipTransferred, error) {
	event := new(VaultManagerOwnershipTransferred)
	if err := _VaultManager.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// VaultManagerVaultCreatedAndRegisteredIterator is returned from FilterVaultCreatedAndRegistered and is used to iterate over the raw logs and unpacked data for VaultCreatedAndRegistered events raised by the VaultManager contract.
type VaultManagerVaultCreatedAndRegisteredIterator struct {
	Event *VaultManagerVaultCreatedAndRegistered // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *VaultManagerVaultCreatedAndRegisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(VaultManagerVaultCreatedAndRegistered)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(VaultManagerVaultCreatedAndRegistered)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *VaultManagerVaultCreatedAndRegisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *VaultManagerVaultCreatedAndRegisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// VaultManagerVaultCreatedAndRegistered represents a VaultCreatedAndRegistered event raised by the VaultManager contract.
type VaultManagerVaultCreatedAndRegistered struct {
	Vault     common.Address
	VaultName string
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterVaultCreatedAndRegistered is a free log retrieval operation binding the contract event 0xca687b51f81494155517fbeb974f3c9c0d0d82d46dccb368be2ea485632c2c93.
//
// Solidity: event VaultCreatedAndRegistered(address indexed vault, string vaultName)
func (_VaultManager *VaultManagerFilterer) FilterVaultCreatedAndRegistered(opts *bind.FilterOpts, vault []common.Address) (*VaultManagerVaultCreatedAndRegisteredIterator, error) {

	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _VaultManager.contract.FilterLogs(opts, "VaultCreatedAndRegistered", vaultRule)
	if err != nil {
		return nil, err
	}
	return &VaultManagerVaultCreatedAndRegisteredIterator{contract: _VaultManager.contract, event: "VaultCreatedAndRegistered", logs: logs, sub: sub}, nil
}

// WatchVaultCreatedAndRegistered is a free log subscription operation binding the contract event 0xca687b51f81494155517fbeb974f3c9c0d0d82d46dccb368be2ea485632c2c93.
//
// Solidity: event VaultCreatedAndRegistered(address indexed vault, string vaultName)
func (_VaultManager *VaultManagerFilterer) WatchVaultCreatedAndRegistered(opts *bind.WatchOpts, sink chan<- *VaultManagerVaultCreatedAndRegistered, vault []common.Address) (event.Subscription, error) {

	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _VaultManager.contract.WatchLogs(opts, "VaultCreatedAndRegistered", vaultRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(VaultManagerVaultCreatedAndRegistered)
				if err := _VaultManager.contract.UnpackLog(event, "VaultCreatedAndRegistered", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseVaultCreatedAndRegistered is a log parse operation binding the contract event 0xca687b51f81494155517fbeb974f3c9c0d0d82d46dccb368be2ea485632c2c93.
//
// Solidity: event VaultCreatedAndRegistered(address indexed vault, string vaultName)
func (_VaultManager *VaultManagerFilterer) ParseVaultCreatedAndRegistered(log types.Log) (*VaultManagerVaultCreatedAndRegistered, error) {
	event := new(VaultManagerVaultCreatedAndRegistered)
	if err := _VaultManager.contract.UnpackLog(event, "VaultCreatedAndRegistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
