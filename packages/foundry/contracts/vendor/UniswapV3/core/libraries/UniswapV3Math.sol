// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { FullMath } from "./FullMath.sol";
import { FixedPoint96 } from "./FixedPoint96.sol";

/// @title UniswapV3Math - Uniswap V3 数学计算库
/// @notice 提供 Uniswap V3 相关的数学计算函数
library UniswapV3Math {
    /// @notice 基于V3流动性原理计算最优交换量
    /// @dev V3的核心：代币数量比例必须匹配价格区间内的价格比例
    /// @param balance0 token0的余额
    /// @param balance1 token1的余额
    /// @param sqrtCurrent 当前价格的平方根
    /// @param sqrtLower 价格区间下限的平方根
    /// @param sqrtUpper 价格区间上限的平方根
    /// @return swapAmount 交换数量，正数表示token0换token1，负数表示token1换token0
    function calculateV3OptimalSwapAmount(
        uint256 balance0,
        uint256 balance1,
        uint160 sqrtCurrent,
        uint160 sqrtLower,
        uint160 sqrtUpper
    ) internal pure returns (int256 swapAmount) {
        if (sqrtCurrent <= sqrtLower) {
            // 当前价格低于区间，全部持有token1，需要将token0全部换成token1
            if (balance0 != 0) {
                swapAmount = int256(balance0);
            } else {
                swapAmount = 0;
            }
        } else if (sqrtCurrent >= sqrtUpper) {
            // 当前价格高于区间，全部持有token0，需要将token1全部换成token0
            if (balance1 != 0) {
                swapAmount = -int256(balance1);
            } else {
                swapAmount = 0;
            }
        } else if (balance1 == 0) {
            // 使用正确的精度计算方法 (参考成功案例)
            uint256 numerator = sqrtUpper - sqrtCurrent;
            uint256 denominator = sqrtUpper - sqrtLower;

            // 使用1000000精度，避免溢出
            uint256 tokenRatio = (numerator * 1000000) / denominator;
            uint256 amountToKeep = (balance0 * tokenRatio) / 1000000;
            uint256 amountToSwap = balance0 - amountToKeep;

            swapAmount = int256(amountToSwap);
        } else {
            // 当前价格在区间内，计算最优比例 - 使用正确的精度计算
            uint256 denominator = sqrtUpper - sqrtLower;

            // 计算token0的最优比例 = (sqrt(upper) - sqrt(current)) / (sqrt(upper) - sqrt(lower))
            uint256 token0Numerator = sqrtUpper - sqrtCurrent;
            uint256 token0Ratio = (token0Numerator * 1000000) / denominator;

            // 计算token1的最优比例 = (sqrt(current) - sqrt(lower)) / (sqrt(upper) - sqrt(lower))
            uint256 token1Numerator = sqrtCurrent - sqrtLower;
            uint256 token1Ratio = (token1Numerator * 1000000) / denominator;

            // 计算当前实际比例
            uint256 currentToken0Ratio = (balance0 * 1000000) / (balance0 + balance1);

            if (currentToken0Ratio > token0Ratio) {
                // token0比例过高，需要换token1
                uint256 amountToKeep = (balance0 * token0Ratio) / 1000000;
                uint256 amountToSwap = balance0 - amountToKeep;

                // 设置合理的最小和最大交换量限制
                uint256 minSwap = balance0 / 100; // 最少交换1%
                uint256 maxSwap = (balance0 * 99) / 100; // 最多交换99%

                if (amountToSwap < minSwap) {
                    amountToSwap = minSwap;
                } else if (amountToSwap > maxSwap) {
                    amountToSwap = maxSwap;
                }

                swapAmount = int256(amountToSwap);
            } else {
                // token1比例过高，需要换token0
                uint256 amountToKeep = (balance1 * token1Ratio) / 1000000;
                uint256 amountToSwap = balance1 - amountToKeep;

                // 设置合理的最小和最大交换量限制
                uint256 minSwap = balance1 / 100; // 最少交换1%
                uint256 maxSwap = (balance1 * 99) / 100; // 最多交换99%

                if (amountToSwap < minSwap) {
                    amountToSwap = minSwap;
                } else if (amountToSwap > maxSwap) {
                    amountToSwap = maxSwap;
                }

                swapAmount = -int256(amountToSwap);
            }
        }
    }

    /// @notice 通用的价格转换计算函数
    /// @param amountIn 输入数量
    /// @param sqrtPriceX96 当前价格的平方根
    /// @param isToken0ToToken1 是否从token0转换为token1
    /// @return 转换后的数量
    function calculatePriceConversion(uint256 amountIn, uint160 sqrtPriceX96, bool isToken0ToToken1)
        internal
        pure
        returns (uint256)
    {
        if (isToken0ToToken1) {
            // token0 -> token1: amountOut = amountIn * sqrtPriceX96^2 / 2^192
            return FullMath.mulDiv(
                FullMath.mulDiv(amountIn, sqrtPriceX96, FixedPoint96.Q96), sqrtPriceX96, FixedPoint96.Q96
            );
        } else {
            // token1 -> token0: amountOut = amountIn * 2^192 / sqrtPriceX96^2
            return FullMath.mulDiv(
                FullMath.mulDiv(amountIn, FixedPoint96.Q96, sqrtPriceX96), FixedPoint96.Q96, sqrtPriceX96
            );
        }
    }

    /// @notice 计算考虑滑点的最小数量
    /// @param amount 原始数量
    /// @param slippageTolerance 滑点容忍度
    /// @return 考虑滑点后的最小数量
    function calculateMinAmount(uint256 amount, uint256 slippageTolerance) internal pure returns (uint256) {
        // 确保滑点容忍度不超过100%
        require(slippageTolerance <= 10000, "Invalid slippage tolerance");
        return (amount * (10000 - slippageTolerance)) / 10000;
    }
}
