// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AStaticUsdtData} from "./AStaticUSDTData.sol";

abstract contract AStaticUSDCData is AStaticUsdtData {
    // Intended to be USDC
    IERC20 internal immutable i_USDC;

    constructor(IERC20 Usdt, IERC20 Usdc) AStaticUsdtData(Usdt) {
        i_USDC = IERC20(Usdc);
    }

    /**
     * @return The USDC token
     */
    function getUsdc() external view returns (IERC20) {
        return i_USDC;
    }
}
