// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract AStaticUsdtData {
    // The following four tokens are the approved tokens the protocol accepts
    // The default values are for Mainnet
    IERC20 internal immutable i_usdt;

    constructor(IERC20 usdt) {
        i_usdt = IERC20(usdt);
    }

    /**
     * @return The WETH token
     */
    function getUsdt() external view returns (IERC20) {
        return i_usdt;
    }
}
