// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import "../../contracts/interfaces/IProtocolAdapter.sol";

// Mock Protocol Adapter for testing
contract MockAdapter is IProtocolAdapter {
    string public name;
    mapping(address => uint256) public investedAmount;

    constructor(string memory _name) {
        name = _name;
    }

    function invest(
        IERC20 asset,
        uint256 amount
    ) external override returns (uint256) {
        investedAmount[address(asset)] += amount;
        return amount;
    }

    function divest(
        IERC20 asset,
        uint256 amount
    ) external override returns (uint256) {
        investedAmount[address(asset)] -= amount;
        return amount;
    }

    function getTotalValue(
        IERC20 asset
    ) external view override returns (uint256) {
        return investedAmount[address(asset)];
    }

    function getName() external view override returns (string memory) {
        return name;
    }
}
