// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IProtocolAdapter } from "./IProtocolAdapter.sol";

interface IVaultShares is IERC4626 {
    struct ConstructorData {
        IERC20 asset;
        uint256 Fee;
        string vaultName;
        string vaultSymbol;
    }

    struct Allocation {
        IProtocolAdapter adapter;
        uint256 allocation;
    }

    function updateHoldingAllocation(Allocation[] memory allocations) external;

    function partialUpdateHoldingAllocation(
        uint256[] memory divestAdapterIndices,
        uint256[] memory divestAmounts,
        uint256[] memory investAdapterIndices,
        uint256[] memory investAmounts,
        uint256[] memory investAllocations
    ) external;

    function withdrawAllInvestments() external;

    function setNotActive() external;
}
