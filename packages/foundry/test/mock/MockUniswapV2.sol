// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockToken.sol";

// Mock Uniswap V2 Pair contract for testing
contract MockUniswapV2Pair is ERC20 {
    address public token0;
    address public token1;
    uint112 public reserve0;
    uint112 public reserve1;
    
    constructor(address _token0, address _token1, string memory name, string memory symbol) ERC20(name, symbol) {
        token0 = _token0;
        token1 = _token1;
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    
    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
    
    function getReserves() external view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, 0);
    }
    
    function setReserves(uint112 _reserve0, uint112 _reserve1) external {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }
}

// Mock Uniswap V2 Factory contract for testing
contract MockUniswapV2Factory {
    mapping(address => mapping(address => address)) public getPair;
    mapping(address => address) public token0;
    mapping(address => address) public token1;
    
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != address(0), "MockUniswapV2Factory: ZERO_ADDRESS");
        require(tokenB != address(0), "MockUniswapV2Factory: ZERO_ADDRESS");
        require(tokenA != tokenB, "MockUniswapV2Factory: IDENTICAL_ADDRESSES");
        
        string memory pairName = string(abi.encodePacked("LP ", ERC20(tokenA).symbol(), "/", ERC20(tokenB).symbol()));
        MockUniswapV2Pair newPair = new MockUniswapV2Pair(tokenA, tokenB, pairName, "LP");
        pair = address(newPair);
        getPair[tokenA][tokenB] = pair;
        getPair[tokenB][tokenA] = pair;
        token0[pair] = tokenA;
        token1[pair] = tokenB;
        return pair;
    }
    
    function setPair(address tokenA, address tokenB, address pair) external {
        getPair[tokenA][tokenB] = pair;
        getPair[tokenB][tokenA] = pair;
        token0[pair] = tokenA;
        token1[pair] = tokenB;
    }
}

// Mock Uniswap V2 Router contract for testing
contract MockUniswapV2Router {
    address public factory;
    address public WETH; // Mock WETH address
    
    // Keep track of token balances for swapping
    mapping(address => uint256) public tokenBalances;
    
    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 /*amountAMin*/,
        uint256 /*amountBMin*/,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(deadline >= block.timestamp, "UniswapV2Router: EXPIRED");
        
        // Transfer tokens from sender to this contract
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);
        
        // Update token balances
        tokenBalances[tokenA] += amountADesired;
        tokenBalances[tokenB] += amountBDesired;
        
        // Get pair address
        address pairAddress = MockUniswapV2Factory(factory).getPair(tokenA, tokenB);
        MockUniswapV2Pair pair = MockUniswapV2Pair(pairAddress);
        
        // Calculate liquidity (simplified)
        liquidity = amountADesired; // Simplified for testing
        
        // Mint LP tokens to 'to' address
        pair.mint(to, liquidity);
        
        amountA = amountADesired;
        amountB = amountBDesired;
        
        // Update reserves
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        reserve0 = uint112(uint256(reserve0) + amountA);
        reserve1 = uint112(uint256(reserve1) + amountB);
        pair.setReserves(reserve0, reserve1);
        
        return (amountA, amountB, liquidity);
    }
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 /*amountAMin*/,
        uint256 /*amountBMin*/,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        require(deadline >= block.timestamp, "UniswapV2Router: EXPIRED");
        
        // Get pair address
        address pairAddress = MockUniswapV2Factory(factory).getPair(tokenA, tokenB);
        MockUniswapV2Pair pair = MockUniswapV2Pair(pairAddress);
        
        // Burn LP tokens from sender
        pair.burn(msg.sender, liquidity);
        
        // Calculate amounts (simplified)
        amountA = liquidity / 2;
        amountB = liquidity / 2;
        
        // Transfer tokens to 'to' address
        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);
        
        // Update token balances
        tokenBalances[tokenA] -= amountA;
        tokenBalances[tokenB] -= amountB;
        
        // Update reserves
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        reserve0 = uint112(uint256(reserve0) - amountA);
        reserve1 = uint112(uint256(reserve1) - amountB);
        pair.setReserves(reserve0, reserve1);
        
        return (amountA, amountB);
    }
    
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(deadline >= block.timestamp, "UniswapV2Router: EXPIRED");
        require(path.length >= 2, "UniswapV2Router: INVALID_PATH");
        
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        
        // Simplified swap - 1:1 ratio
        amounts[1] = amountIn;
        require(amounts[1] >= amountOutMin, "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        
        // Transfer input token from sender
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        
        // Update token balances
        tokenBalances[path[0]] += amountIn;
        
        // Mint output token to 'to' address (instead of transfer from router balance)
        MockToken(path[1]).mint(to, amounts[1]);
        
        return amounts;
    }
    
    function getAmountsOut(uint256 amountIn, address[] memory /*path*/) external pure returns (uint256[] memory amounts) {
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountIn; // 1:1 ratio for simplicity
        return amounts;
    }
    
    // Helper function to mint tokens to this contract for testing
    function mintToken(address token, uint256 amount) external {
        MockToken(token).mint(address(this), amount);
        tokenBalances[token] += amount;
    }
}