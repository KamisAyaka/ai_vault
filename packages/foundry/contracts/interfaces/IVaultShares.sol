// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVaultShares is IERC4626 {
    /**
     * @notice 该结构体存储由金库守护者设置的底层资产代币投资比例
     * @notice holdAllocation 表示保留在金库中的代币比例（不用于Uniswap v2或Aave v3投资）
     * @notice uniswapAllocation 表示添加到Uniswap v2的流动性比例
     * @notice aaveAllocation 表示在Aave v3中作为借贷金额的比例
     */
    struct AllocationData {
        uint256 aaveAllocation;
        uint256 uniswapV2Allocation;
        uint256 uniswapV3Allocation;
    }
    struct ConstructorData {
        IERC20 asset;
        IERC20 counterPartyTokenV2;
        IERC20 counterPartyTokenV3;
        AllocationData allocationData;
        uint256 DaoCut;
        bool isApprovedtoken;
        address aavePool;
        address uniswapV2Router;
        address uniswapV3Router;
        address governanceGuardian;
        string vaultName;
        string vaultSymbol;
    }

    function updateHoldingAllocation(
        AllocationData memory tokenAllocationData
    ) external;

    function updateUniswapSlippage(uint256 tolerance) external;

    function updateCounterPartyTokenV2(IERC20 newCounterPartyToken) external;

    function setNotActive() external;
}
