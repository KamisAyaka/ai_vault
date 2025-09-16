// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../contracts/vendor/AaveV3/DataTypes.sol";

// Mock AToken contract for testing
contract MockAToken is ERC20 {
    address public asset;
    
    constructor(address _asset, string memory name, string memory symbol) ERC20(name, symbol) {
        asset = _asset;
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    
    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

// Mock Aave Pool contract for testing
contract MockAavePool {
    mapping(address => MockAToken) public aTokenAddresses;
    mapping(address => uint256) public reserveNormalizedIncomes;
    
    constructor() {
        reserveNormalizedIncomes[address(0)] = 1e27; // Default normalized income
    }
    
    // Helper function to set reserve normalized income for an asset
    function setReserveNormalizedIncome(address asset, uint256 income) external {
        reserveNormalizedIncomes[asset] = income;
    }
    
    // Helper function to pre-create aToken for an asset
    function createAToken(address asset) external {
        if (address(aTokenAddresses[asset]) == address(0)) {
            aTokenAddresses[asset] = new MockAToken(asset, string(abi.encodePacked("a", ERC20(asset).name())), "aTKN");
        }
    }
    
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 /*referralCode*/) external {
        // Create aToken if not exists
        if (address(aTokenAddresses[asset]) == address(0)) {
            aTokenAddresses[asset] = new MockAToken(asset, string(abi.encodePacked("a", ERC20(asset).name())), "aTKN");
        }
        
        // Transfer asset from sender to this contract
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        
        // Mint aTokens to onBehalfOf
        aTokenAddresses[asset].mint(onBehalfOf, amount);
    }
    
    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        // Burn aTokens from msg.sender
        aTokenAddresses[asset].burn(msg.sender, amount);
        
        // Transfer assets to 'to' address
        IERC20(asset).transfer(to, amount);
        
        return amount;
    }
    
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory) {
        DataTypes.ReserveData memory data;
        data.aTokenAddress = address(aTokenAddresses[asset]);
        return data;
    }
    
    function getReserveNormalizedIncome(address asset) external view returns (uint256) {
        if (reserveNormalizedIncomes[asset] == 0) {
            return 1e27; // Default value
        }
        return reserveNormalizedIncomes[asset];
    }
}