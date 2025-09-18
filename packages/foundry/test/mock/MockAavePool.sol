// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../contracts/vendor/AaveV3/DataTypes.sol";

/// -----------------------------------------------------------------------
/// Mock Aave V3 Pool
/// -----------------------------------------------------------------------
contract MockAavePool {
    mapping(address => address) public aTokenAddresses; // token => aToken
    mapping(address => uint256) public normalizedIncome; // token => normalized income
    mapping(address => DataTypes.ReserveData) public reserveData; // token => reserve data

    constructor() {
        // 初始化一些默认值
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 /* referralCode */ ) external {
        // 模拟供应资产到 Aave
        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        // 获取或创建 aToken
        address aToken = aTokenAddresses[asset];
        if (aToken == address(0)) {
            // 创建新的 aToken
            aToken = address(new MockAToken(asset));
            aTokenAddresses[asset] = aToken;

            // 设置储备数据
            DataTypes.ReserveData memory data;
            data.aTokenAddress = aToken;
            data.liquidityIndex = 1e27; // 1.0 normalized income
            reserveData[asset] = data;
        }

        // 铸造 aToken 给接收者
        MockAToken(aToken).mint(onBehalfOf, amount);
        normalizedIncome[asset] = 1e27; // 1.0 normalized income
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        // 获取 aToken 地址
        address aToken = aTokenAddresses[asset];
        require(aToken != address(0), "Asset not supported");

        // 如果请求的金额是最大值，则提取所有可用资产
        if (amount == type(uint256).max) {
            uint256 userBalance = MockAToken(aToken).balanceOf(msg.sender);
            MockAToken(aToken).burn(msg.sender, userBalance);
            IERC20(asset).transfer(to, userBalance);
            return userBalance;
        } else {
            // 销毁 aToken
            MockAToken(aToken).burn(msg.sender, amount);

            // 模拟从 Aave 提取资产
            IERC20(asset).transfer(to, amount);
            return amount;
        }
    }

    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory) {
        return reserveData[asset];
    }

    function getReserveNormalizedIncome(address asset) external view returns (uint256) {
        return normalizedIncome[asset];
    }

    // Helper functions for testing
    function createAToken(address asset) external {
        address aToken = address(new MockAToken(asset));
        aTokenAddresses[asset] = aToken;

        // 设置储备数据
        DataTypes.ReserveData memory data;
        data.aTokenAddress = aToken;
        data.liquidityIndex = 1e27; // 1.0 normalized income
        reserveData[asset] = data;
    }

    function setReserveNormalizedIncome(address asset, uint256 normalizedIncomeValue) external {
        normalizedIncome[asset] = normalizedIncomeValue;
    }
}

/// -----------------------------------------------------------------------
/// Mock Aave aToken
/// -----------------------------------------------------------------------
contract MockAToken is IERC20 {
    IERC20 public immutable UNDERLYING_ASSET_ADDRESS;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    constructor(address underlyingAsset) {
        UNDERLYING_ASSET_ADDRESS = IERC20(underlyingAsset);
        name = "aToken";
        symbol = "aTKN";
    }

    function mint(address user, uint256 amount) external {
        totalSupply += amount;
        balanceOf[user] += amount;
    }

    function burn(address user, uint256 amount) external {
        require(balanceOf[user] >= amount, "Insufficient balance");
        totalSupply -= amount;
        balanceOf[user] -= amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
}
