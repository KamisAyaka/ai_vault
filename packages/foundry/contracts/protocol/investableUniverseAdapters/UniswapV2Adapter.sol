// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IProtocolAdapter } from "../../interfaces/IProtocolAdapter.sol";
import { IUniswapV2Pair } from "../../vendor/UniswapV2/IUniswapV2Pair.sol";
import { IUniswapV2Router01 } from "../../vendor/UniswapV2/IUniswapV2Router01.sol";
import { IUniswapV2Factory } from "../../vendor/UniswapV2/IUniswapV2Factory.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract UniswapAdapter is IProtocolAdapter, Ownable {
    error UniswapAdapter__InvalidSlippageTolerance();
    error UniswapAdapter__InvalidCounterPartyToken();
    error UniswapAdapter__InvalidToken();
    error OnlyVaultCanCallThisFunction();

    using SafeERC20 for IERC20;

    uint256 internal constant BASIS_POINTS_DIVISOR = 1e4; // 10000 basis points = 100%
    uint256 internal constant DEADLINE_INTERVAL = 300; // 5 minutes deadline interval

    IUniswapV2Router01 internal immutable i_uniswapRouter;
    IUniswapV2Factory internal immutable i_uniswapFactory;

    struct TokenConfig {
        uint256 slippageTolerance; // 滑点容忍 (以基点为单位，100 = 1%)
        IERC20 counterPartyToken; // 配对代币
        address VaultAddress;
    }

    // 代币地址到配置的映射
    mapping(IERC20 => TokenConfig) public s_tokenConfigs;

    event UniswapInvested(
        address indexed token, uint256 tokenAmount, uint256 counterPartyTokenAmount, uint256 liquidity
    );
    event UniswapDivested(address indexed token, uint256 tokenAmount, uint256 counterPartyTokenAmount);
    event TokenConfigUpdated(address indexed token);

    constructor(address uniswapRouter) Ownable(msg.sender) {
        i_uniswapRouter = IUniswapV2Router01(uniswapRouter);
        i_uniswapFactory = IUniswapV2Factory(IUniswapV2Router01(i_uniswapRouter).factory());
    }

    /**
     * @notice 为特定代币设置配置
     * @param token 代币地址
     * @param slippageTolerance 滑点容忍度
     * @param counterPartyToken 配对代币
     */
    function setTokenConfig(IERC20 token, uint256 slippageTolerance, IERC20 counterPartyToken, address VaultAddress)
        external
        onlyOwner
    {
        if (address(token) == address(0)) {
            revert UniswapAdapter__InvalidToken();
        }

        if (slippageTolerance > BASIS_POINTS_DIVISOR) {
            revert UniswapAdapter__InvalidSlippageTolerance();
        }

        if (address(counterPartyToken) == address(0)) {
            revert UniswapAdapter__InvalidCounterPartyToken();
        }

        s_tokenConfigs[token] = TokenConfig({
            slippageTolerance: slippageTolerance,
            counterPartyToken: counterPartyToken,
            VaultAddress: VaultAddress
        });

        emit TokenConfigUpdated(address(token));
    }

    /**
     * @notice 为特定代币设置滑点容忍度
     * @param token 代币地址
     * @param slippageTolerance 滑点容忍度
     */
    function UpdateTokenSlippageTolerance(IERC20 token, uint256 slippageTolerance) external onlyOwner {
        if (address(token) == address(0)) {
            revert UniswapAdapter__InvalidToken();
        }

        if (slippageTolerance > BASIS_POINTS_DIVISOR) {
            revert UniswapAdapter__InvalidSlippageTolerance();
        }

        TokenConfig storage config = s_tokenConfigs[token];
        config.slippageTolerance = slippageTolerance;

        emit TokenConfigUpdated(address(token));
    }

    /**
     * @notice 更新代币配置并自动重新投资
     * @param token 代币地址
     * @param counterPartyToken 配对代币
     */
    function updateTokenConfigAndReinvest(IERC20 token, IERC20 counterPartyToken) external onlyOwner {
        // 验证输入参数
        if (address(token) == address(0)) {
            revert UniswapAdapter__InvalidToken();
        }

        if (address(counterPartyToken) == address(0)) {
            revert UniswapAdapter__InvalidCounterPartyToken();
        }

        TokenConfig memory config = getTokenConfig(token);
        if (config.VaultAddress == address(0)) {
            return;
        }

        // 获取当前LP代币余额
        address pairAddress = i_uniswapFactory.getPair(address(token), address(config.counterPartyToken));
        uint256 lpBalance = IERC20(pairAddress).balanceOf(address(this));

        // 如果有持仓，则先撤资
        if (lpBalance > 0) {
            // 执行撤资操作
            _divest(token, lpBalance, config);
        }

        // 更新配置
        s_tokenConfigs[token].counterPartyToken = counterPartyToken;

        // 获取适配器中可用的资产余额并重新投资
        uint256 availableAssets = token.balanceOf(address(this));
        if (availableAssets > 0) {
            _invest(token, availableAssets, s_tokenConfigs[token]);
        }
        emit TokenConfigUpdated(address(token));
    }

    /**
     * @notice 金库仅持有一种资产代币。但我们需要提供流动性到Uniswap的交易对
     * @notice 所以如果资产是USDC，我们用一半的资产用来兑换配对代币
     * @notice 然后将获得的代币添加到Uniswap池，铸造LP代币给金库
     * @param asset 金库的底层资产代币
     * @param amount 用于投资的资产数量
     */
    function invest(IERC20 asset, uint256 amount) external override returns (uint256) {
        TokenConfig memory config = getTokenConfig(asset);
        if (msg.sender != config.VaultAddress) {
            revert OnlyVaultCanCallThisFunction();
        }

        // 将资金从金库转移到适配器
        asset.transferFrom(msg.sender, address(this), amount);

        return _invest(asset, amount, config);
    }

    /**
     * @notice 内部投资函数
     * @param asset 资产代币
     * @param amount 投资金额
     * @param config 代币配置
     */
    function _invest(IERC20 asset, uint256 amount, TokenConfig memory config) internal returns (uint256) {
        uint256 amountOfTokenToSwap = amount / 2;

        // 动态生成路径数组
        address[] memory path = new address[](2);
        path[0] = address(asset);
        path[1] = address(config.counterPartyToken);

        // 执行兑换并获取实际兑换数量
        uint256 actualTokenB = _swap(
            path,
            amountOfTokenToSwap,
            (
                i_uniswapRouter.getAmountsOut(amountOfTokenToSwap, path)[1]
                    * (BASIS_POINTS_DIVISOR - config.slippageTolerance)
            ) / BASIS_POINTS_DIVISOR
        );

        // 批准流动性添加
        asset.forceApprove(address(i_uniswapRouter), amountOfTokenToSwap);

        config.counterPartyToken.forceApprove(address(i_uniswapRouter), actualTokenB);

        // 添加流动性（使用实际兑换数量）
        (uint256 tokenAmount, uint256 counterPartyTokenAmount, uint256 liquidity) = i_uniswapRouter.addLiquidity({
            tokenA: address(asset),
            tokenB: address(config.counterPartyToken),
            amountADesired: amountOfTokenToSwap,
            amountBDesired: actualTokenB,
            amountAMin: (amountOfTokenToSwap * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,
            amountBMin: (actualTokenB * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR,
            to: address(this), // LP代币发送到适配器
            deadline: block.timestamp + DEADLINE_INTERVAL
        });

        emit UniswapInvested(address(asset), tokenAmount, counterPartyTokenAmount, liquidity);
        return amount;
    }

    /**
     * @notice 销毁添加的流动性对应的LP代币
     * @notice 将非金库底层资产的代币兑换回底层资产
     * @param asset 金库的底层资产代币
     * @param liquidityAmount 要销毁的LP代币数量
     */
    function divest(IERC20 asset, uint256 liquidityAmount) external override returns (uint256) {
        TokenConfig memory config = getTokenConfig(asset);
        if (msg.sender != config.VaultAddress) {
            revert OnlyVaultCanCallThisFunction();
        }

        uint256 tokenAmount = _divest(asset, liquidityAmount, config);

        // 将回收的资金转回金库
        asset.transfer(msg.sender, tokenAmount);

        return tokenAmount;
    }

    /**
     * @notice 内部函数：销毁添加的流动性对应的LP代币
     * @notice 将非金库底层资产的代币兑换回底层资产
     * @param asset 金库的底层资产代币
     * @param liquidityAmount 要销毁的LP代币数量
     * @param config 代币配置
     */
    function _divest(IERC20 asset, uint256 liquidityAmount, TokenConfig memory config) internal returns (uint256) {
        if (address(config.counterPartyToken) == address(0)) {
            revert UniswapAdapter__InvalidCounterPartyToken();
        }

        address pairAddress = i_uniswapFactory.getPair(address(asset), address(config.counterPartyToken));
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();

        // 计算滑点保护值
        (uint256 minToken, uint256 minCounter) = _calculateMinAmounts(
            asset, pair, reserve0, reserve1, totalSupply, liquidityAmount, config.slippageTolerance
        );

        // 执行流动性移除
        (uint256 tokenAmount, uint256 counterPartyAmount) = i_uniswapRouter.removeLiquidity({
            tokenA: address(asset),
            tokenB: address(config.counterPartyToken),
            liquidity: liquidityAmount,
            amountAMin: minToken,
            amountBMin: minCounter,
            to: address(this), // 资金发送到适配器
            deadline: block.timestamp + DEADLINE_INTERVAL
        });

        // 将配对代币兑换回底层资产
        if (counterPartyAmount > 0) {
            // 创建正确的交易路径（始终从counterPartyToken兑换到token）
            address[] memory path = new address[](2);
            path[0] = address(config.counterPartyToken);
            path[1] = address(asset);

            uint256 expectedOut = i_uniswapRouter.getAmountsOut(counterPartyAmount, path)[1];
            uint256 minOut = (expectedOut * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR;

            uint256 swapAmount = _swap(path, counterPartyAmount, minOut);
            tokenAmount += swapAmount; // 累加swap获得的底层代币
        }

        emit UniswapDivested(address(asset), tokenAmount, counterPartyAmount);
        return tokenAmount;
    }

    /**
     * @notice 执行代币兑换的通用逻辑
     * @param path 交换路径
     * @param amountIn 输入代币数量
     * @param minOut 最小输出数量（用于滑点保护）
     * @return 实际兑换获得的代币数量
     */
    function _swap(address[] memory path, uint256 amountIn, uint256 minOut) internal returns (uint256) {
        // 执行兑换
        IERC20(path[0]).forceApprove(address(i_uniswapRouter), amountIn);

        uint256[] memory amounts = i_uniswapRouter.swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: minOut,
            path: path,
            to: address(this), // 修改为发送给适配器
            // 使用block.timestamp + DEADLINE_INTERVAL作为deadline是安全的
            // 因为这是一个相对较短的时间间隔（300秒），矿工操纵的影响有限
            deadline: block.timestamp + DEADLINE_INTERVAL
        });

        return amounts[1];
    }

    /// @dev 计算移除流动性时的最小代币数量（考虑滑点容忍度）
    /// @param token 用户持有的代币地址
    /// @param pair Uniswap V2池合约
    /// @param reserve0 池中代币0的储备量
    /// @param reserve1 池中代币1的储备量
    /// @param totalSupply LP代币总供应量
    /// @param liquidityAmount 要移除的流动性数量
    /// @param slippageTolerance 滑点容忍度
    /// @return amount0 应获得的代币0最小数量
    /// @return amount1 应获得的代币1最小数量
    function _calculateMinAmounts(
        IERC20 token,
        IUniswapV2Pair pair,
        uint112 reserve0,
        uint112 reserve1,
        uint256 totalSupply,
        uint256 liquidityAmount,
        uint256 slippageTolerance
    ) private view returns (uint256, uint256) {
        // 根据代币在交易对中的位置计算兑换比例
        if (address(token) == pair.token0()) {
            // token0对应reserve0，token1对应reserve1
            // 计算扣除滑点后的最小兑换数量
            return (
                (((uint256(reserve0) * liquidityAmount) / totalSupply) * (BASIS_POINTS_DIVISOR - slippageTolerance))
                    / BASIS_POINTS_DIVISOR,
                (((uint256(reserve1) * liquidityAmount) / totalSupply) * (BASIS_POINTS_DIVISOR - slippageTolerance))
                    / BASIS_POINTS_DIVISOR
            );
        }
        // token位置相反时交换计算顺序
        return (
            (((uint256(reserve1) * liquidityAmount) / totalSupply) * (BASIS_POINTS_DIVISOR - slippageTolerance))
                / BASIS_POINTS_DIVISOR,
            (((uint256(reserve0) * liquidityAmount) / totalSupply) * (BASIS_POINTS_DIVISOR - slippageTolerance))
                / BASIS_POINTS_DIVISOR
        );
    }

    // 计算 Uniswap LP Token 对应的底层资产价值
    function getTotalValue(IERC20 asset) external view override returns (uint256) {
        TokenConfig memory config = getTokenConfig(asset);
        address pairAddress = i_uniswapFactory.getPair(address(asset), address(config.counterPartyToken));

        uint256 liquidityTokens = IERC20(pairAddress).balanceOf(address(this)); // 查询适配器的LP代币余额
        // 使用严格相等性检查是安全的，因为代币余额是整数值，不会有精度问题
        if (liquidityTokens == 0) return 0;

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();

        // 计算LP代币对应的两种资产数量
        uint256 amount0 = (uint256(reserve0) * liquidityTokens) / totalSupply;
        uint256 amount1 = (uint256(reserve1) * liquidityTokens) / totalSupply;

        // 返回正确的底层资产价值
        if (address(asset) == pair.token0()) {
            return amount0 + (amount1 * reserve0) / reserve1; // 将amount1(WETH)转换为底层资产
        } else if (address(asset) == pair.token1()) {
            return amount1 + (amount0 * reserve1) / reserve0; // 将amount0(USDC)转换为底层资产
        } else {
            revert("Invalid asset pair");
        }
    }

    function getName() external pure override returns (string memory) {
        return "UniswapV2";
    }

    /**
     * @notice 获取特定代币的配置
     * @param token 代币地址
     * @return TokenConfig 代币配置
     */
    function getTokenConfig(IERC20 token) public view returns (TokenConfig memory) {
        TokenConfig memory config = s_tokenConfigs[token];
        return config;
    }
}
