// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { FullMath } from "./FullMath.sol";
import { FixedPoint96 } from "./FixedPoint96.sol";

/// @title UniswapV3Math - Uniswap V3 数学计算库
/// @notice 提供 Uniswap V3 相关的数学计算函数
library UniswapV3Math {
    /// @notice 基于V3流动性原理计算最优交换量
    /// @dev V3的核心：代币数量比例必须匹配价格区间内的价格比例
    /// @param totalAmount 总代币数量
    /// @param sqrtPriceX96 当前价格的平方根
    /// @param sqrtRatioAX96 价格区间下限的平方根
    /// @param sqrtRatioBX96 价格区间上限的平方根
    /// @param isToken1ToSwap 是否交换token1到token0
    /// @return 需要交换的数量
    function calculateV3OptimalSwapAmount(
        uint256 totalAmount,
        uint160 sqrtPriceX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        bool isToken1ToSwap
    ) internal pure returns (uint256) {
        // V3流动性原理：在价格区间内，代币比例 = (sqrt(upper) - sqrt(current)) / (sqrt(upper) - sqrt(lower))
        uint256 sqrtCurrent = uint256(sqrtPriceX96);
        uint256 sqrtLower = uint256(sqrtRatioAX96);
        uint256 sqrtUpper = uint256(sqrtRatioBX96);

        // 处理边界情况：根据交换方向和价格位置确定是否需要交换
        if (sqrtCurrent <= sqrtLower) {
            // 当前价格低于区间
            return isToken1ToSwap ? 0 : totalAmount; // token1不需要交换，token0需要全部交换
        } else if (sqrtCurrent >= sqrtUpper) {
            // 当前价格高于区间
            return isToken1ToSwap ? totalAmount : 0; // token1需要全部交换，token0不需要交换
        }

        // 当前价格在区间内，计算最优比例
        uint256 numerator;
        if (isToken1ToSwap) {
            // token1的比例 = (sqrt(current) - sqrt(lower)) / (sqrt(upper) - sqrt(lower))
            numerator = sqrtCurrent - sqrtLower;
        } else {
            // token0的比例 = (sqrt(upper) - sqrt(current)) / (sqrt(upper) - sqrt(lower))
            numerator = sqrtUpper - sqrtCurrent;
        }

        uint256 denominator = sqrtUpper - sqrtLower;

        // 使用高精度计算，避免舍入误差
        uint256 tokenRatio = (numerator * 1000000) / denominator;
        uint256 amountToKeep = (totalAmount * tokenRatio) / 1000000;
        uint256 amountToSwap = totalAmount - amountToKeep;

        // 设置合理的最小和最大交换量限制
        uint256 minSwap = totalAmount / 100; // 最少交换1%
        uint256 maxSwap = (totalAmount * 99) / 100; // 最多交换99%

        if (amountToSwap < minSwap && totalAmount > minSwap) {
            amountToSwap = minSwap;
        }
        if (amountToSwap > maxSwap) {
            amountToSwap = maxSwap;
        }

        return amountToSwap;
    }

    /// @notice 计算代币价值转换
    /// @param amount0 token0的数量
    /// @param amount1 token1的数量
    /// @param sqrtPriceX96 当前价格的平方根
    /// @param isToken0ToToken1 是否将token0转换为token1的价值
    /// @return 转换后的总价值
    function calculateTokenValue(uint256 amount0, uint256 amount1, uint160 sqrtPriceX96, bool isToken0ToToken1)
        internal
        pure
        returns (uint256)
    {
        if (isToken0ToToken1) {
            // 将token0转换为token1的价值
            uint256 token0ValueInToken1 = FullMath.mulDiv(amount0, sqrtPriceX96, FixedPoint96.Q96);
            token0ValueInToken1 = FullMath.mulDiv(token0ValueInToken1, sqrtPriceX96, FixedPoint96.Q96);
            return amount1 + token0ValueInToken1;
        } else {
            // 将token1转换为token0的价值
            uint256 token1ValueInToken0 = FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtPriceX96);
            token1ValueInToken0 = FullMath.mulDiv(token1ValueInToken0, FixedPoint96.Q96, sqrtPriceX96);
            return amount0 + token1ValueInToken0;
        }
    }

    /// @notice 计算考虑滑点的最小数量
    /// @param amount 原始数量
    /// @param slippageTolerance 滑点容忍度
    /// @return 考虑滑点后的最小数量
    function calculateMinAmount(uint256 amount, uint256 slippageTolerance) internal pure returns (uint256) {
        return (amount * (10000 - slippageTolerance)) / 10000;
    }
}
