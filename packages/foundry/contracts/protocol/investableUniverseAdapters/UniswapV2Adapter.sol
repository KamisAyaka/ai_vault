// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IProtocolAdapter } from "../../interfaces/IProtocolAdapter.sol";
import { IUniswapV2Pair } from "../../vendor/UniswapV2/IUniswapV2Pair.sol";
import { IUniswapV2Router01 } from "../../vendor/UniswapV2/IUniswapV2Router01.sol";
import { IUniswapV2Factory } from "../../vendor/UniswapV2/IUniswapV2Factory.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract UniswapV2Adapter is IProtocolAdapter, Ownable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            常量定义
    //////////////////////////////////////////////////////////////*/
    uint256 internal constant BASIS_POINTS_DIVISOR = 1e4; // 10000 basis points = 100%
    uint256 internal constant DEADLINE_INTERVAL = 300; // 5 minutes deadline interval

    /*//////////////////////////////////////////////////////////////
                            状态变量
    //////////////////////////////////////////////////////////////*/
    IUniswapV2Router01 internal immutable i_uniswapRouter;
    IUniswapV2Factory internal i_uniswapFactory;

    // 代币地址到配置的映射
    mapping(IERC20 => TokenConfig) public s_tokenConfigs;

    /*//////////////////////////////////////////////////////////////
                                 事件
    //////////////////////////////////////////////////////////////*/
    event TokenConfigSet(
        IERC20 indexed token, uint256 slippageTolerance, IERC20 indexed counterPartyToken, address indexed vault
    );
    event TokenConfigUpdated(IERC20 indexed token, uint256 slippageTolerance);
    event TokenConfigReinvested(IERC20 indexed token, IERC20 indexed newCounterPartyToken);
    event UniswapInvested(
        IERC20 indexed token, uint256 tokenAmount, uint256 counterPartyTokenAmount, uint256 liquidity
    );
    event UniswapDivested(
        IERC20 indexed token, uint256 tokenAmount, uint256 counterPartyTokenAmount, uint256 liquidity
    );

    /*//////////////////////////////////////////////////////////////
                            错误定义
    //////////////////////////////////////////////////////////////*/
    error UniswapAdapter__InvalidSlippageTolerance();
    error UniswapAdapter__InvalidCounterPartyToken();
    error UniswapAdapter__InvalidToken();
    error OnlyVaultCanCallThisFunction();

    /*//////////////////////////////////////////////////////////////
                            结构体定义
    //////////////////////////////////////////////////////////////*/
    struct TokenConfig {
        uint256 slippageTolerance; // 滑点容忍 (以基点为单位，100 = 1%)
        IERC20 counterPartyToken; // 配对代币
        address VaultAddress;
        IUniswapV2Pair pair; // 缓存的交易对接口实例
    }

    /*//////////////////////////////////////////////////////////////
                               构造函数
    //////////////////////////////////////////////////////////////*/
    constructor(address uniswapRouter, address uniswapFactory) Ownable(msg.sender) {
        i_uniswapRouter = IUniswapV2Router01(uniswapRouter);
        i_uniswapFactory = IUniswapV2Factory(uniswapFactory);
    }

    /**
     * @notice 初始化factory地址（在部署后调用）
     * @dev 保留此函数以兼容性，但现在factory在构造函数中设置
     */
    function initializeFactory() external onlyOwner {
        // 如果factory已经设置，则不需要重新设置
        if (address(i_uniswapFactory) != address(0)) {
            return;
        }

        i_uniswapFactory = IUniswapV2Factory(IUniswapV2Router01(i_uniswapRouter).factory());
    }

    /*//////////////////////////////////////////////////////////////
                               外部函数（管理者调用）
    //////////////////////////////////////////////////////////////*/

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

        // 计算并缓存pair接口实例
        address pairAddress = i_uniswapFactory.getPair(address(token), address(counterPartyToken));

        // 如果pair不存在，则设置为零地址，稍后可以创建
        if (pairAddress == address(0)) {
            // 可以在这里创建pair，或者要求pair必须存在
            // 为了安全起见，我们要求pair必须预先存在
            revert("PAIR_NOT_EXISTS");
        }

        s_tokenConfigs[token] = TokenConfig({
            slippageTolerance: slippageTolerance,
            counterPartyToken: counterPartyToken,
            VaultAddress: VaultAddress,
            pair: IUniswapV2Pair(pairAddress)
        });

        emit TokenConfigSet(token, slippageTolerance, counterPartyToken, VaultAddress);
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

        emit TokenConfigUpdated(token, slippageTolerance);
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

        // 如果有持仓，先完全撤资
        uint256 currentAssetValue = getTotalValue(token);
        if (currentAssetValue > 0) {
            _divest(token, currentAssetValue, config);
        }

        // 更新配置并重新投资所有可用资产
        // 计算新的pair接口实例
        address newPairAddress = i_uniswapFactory.getPair(address(token), address(counterPartyToken));

        s_tokenConfigs[token].counterPartyToken = counterPartyToken;
        s_tokenConfigs[token].pair = IUniswapV2Pair(newPairAddress);

        uint256 availableAssets = token.balanceOf(address(this));
        if (availableAssets > 0) {
            _invest(token, availableAssets);
        }

        emit TokenConfigReinvested(token, counterPartyToken);
    }

    /*//////////////////////////////////////////////////////////////
                               外部函数（金库调用）
    //////////////////////////////////////////////////////////////*/

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
        asset.safeTransferFrom(msg.sender, address(this), amount);

        return _invest(asset, amount);
    }

    /**
     * @notice 从 Uniswap V2 协议中撤资
     * @notice 将非金库底层资产的代币兑换回底层资产
     * @param asset 金库的底层资产代币
     * @param amount 要撤资的底层资产代币数量
     */
    function divest(IERC20 asset, uint256 amount) external override returns (uint256) {
        TokenConfig memory config = getTokenConfig(asset);
        if (msg.sender != config.VaultAddress) {
            revert OnlyVaultCanCallThisFunction();
        }

        uint256 tokenAmount = _divest(asset, amount, config);

        // 将回收的资金转回金库
        asset.safeTransfer(msg.sender, tokenAmount);

        return tokenAmount;
    }

    /*//////////////////////////////////////////////////////////////
                               内部函数
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 内部投资函数
     * @param asset 资产代币
     * @param amount 投资金额
     */
    function _invest(IERC20 asset, uint256 amount) internal returns (uint256) {
        TokenConfig memory config = s_tokenConfigs[asset];
        uint256 amountOfTokenToSwap = amount / 2;

        // 动态生成路径数组
        address[] memory path = new address[](2);
        path[0] = address(asset);
        path[1] = address(config.counterPartyToken);

        // 执行兑换并获取实际兑换数量
        uint256 expectedTokenB = i_uniswapRouter.getAmountsOut(amountOfTokenToSwap, path)[1];
        uint256 minTokenB = (expectedTokenB * (BASIS_POINTS_DIVISOR - config.slippageTolerance)) / BASIS_POINTS_DIVISOR;
        uint256 actualTokenB = _swap(path, amountOfTokenToSwap, minTokenB);

        // 批准流动性添加
        asset.forceApprove(address(i_uniswapRouter), amountOfTokenToSwap);
        config.counterPartyToken.forceApprove(address(i_uniswapRouter), actualTokenB);

        // 计算滑点保护的最小数量
        (uint256 amountAMin, uint256 amountBMin) = _calculateMinAmounts(
            asset, config.counterPartyToken, amountOfTokenToSwap, actualTokenB, config.slippageTolerance
        );

        // 添加流动性
        (uint256 tokenAmount, uint256 counterPartyTokenAmount, uint256 liquidity) = i_uniswapRouter.addLiquidity({
            tokenA: address(asset),
            tokenB: address(config.counterPartyToken),
            amountADesired: amountOfTokenToSwap,
            amountBDesired: actualTokenB,
            amountAMin: amountAMin,
            amountBMin: amountBMin,
            to: address(this),
            deadline: block.timestamp + DEADLINE_INTERVAL
        });

        emit UniswapInvested(asset, tokenAmount, counterPartyTokenAmount, liquidity);
        return amount;
    }

    /**
     * @notice 内部函数：根据代币数量撤资
     * @notice 将非金库底层资产的代币兑换回底层资产
     * @param asset 金库的底层资产代币
     * @param tokenAmount 要撤资的底层资产代币数量
     * @param config 代币配置
     */
    function _divest(IERC20 asset, uint256 tokenAmount, TokenConfig memory config) internal returns (uint256) {
        if (address(config.counterPartyToken) == address(0)) {
            revert UniswapAdapter__InvalidCounterPartyToken();
        }

        IUniswapV2Pair pair = config.pair;

        // 获取适配器持有的LP代币余额
        uint256 lpBalance = IERC20(address(pair)).balanceOf(address(this));
        if (lpBalance == 0) {
            return 0;
        }

        // 使用已有的getTotalValue函数计算当前资产总价值
        uint256 currentAssetValue = getTotalValue(asset);

        // 如果请求撤资的数量大于等于当前资产价值，则完全撤资
        uint256 liquidityToRemove;
        if (tokenAmount >= currentAssetValue) {
            liquidityToRemove = lpBalance;
        } else {
            // 部分撤资：根据代币数量比例计算需要移除的LP代币数量
            liquidityToRemove = (lpBalance * tokenAmount) / currentAssetValue;
        }

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();

        uint256 amount0 = (uint256(reserve0) * liquidityToRemove) / totalSupply;
        uint256 amount1 = (uint256(reserve1) * liquidityToRemove) / totalSupply;

        // 批准 router 转移 LP 代币
        IERC20(address(pair)).forceApprove(address(i_uniswapRouter), liquidityToRemove);

        // 计算滑点保护的最小数量
        (uint256 amountAMin, uint256 amountBMin) =
            _calculateMinAmounts(asset, config.counterPartyToken, amount0, amount1, config.slippageTolerance);

        // 执行流动性移除
        (uint256 actualTokenAmount, uint256 counterPartyAmount) = i_uniswapRouter.removeLiquidity({
            tokenA: address(asset),
            tokenB: address(config.counterPartyToken),
            liquidity: liquidityToRemove,
            amountAMin: amountAMin,
            amountBMin: amountBMin,
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
            actualTokenAmount += swapAmount; // 累加swap获得的底层代币
        }

        emit UniswapDivested(asset, actualTokenAmount, counterPartyAmount, liquidityToRemove);
        return actualTokenAmount;
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
            deadline: block.timestamp + DEADLINE_INTERVAL
        });

        return amounts[1];
    }

    /**
     * @notice 计算滑点保护的最小数量
     * @param asset 底层资产代币
     * @param counterPartyToken 配对代币
     * @param amount0 token0的数量
     * @param amount1 token1的数量
     * @param slippageTolerance 滑点容忍度
     * @return amountAMin 资产代币的最小数量
     * @return amountBMin 配对代币的最小数量
     */
    function _calculateMinAmounts(
        IERC20 asset,
        IERC20 counterPartyToken,
        uint256 amount0,
        uint256 amount1,
        uint256 slippageTolerance
    ) internal pure returns (uint256 amountAMin, uint256 amountBMin) {
        uint256 slippageMultiplier = BASIS_POINTS_DIVISOR - slippageTolerance;

        if (address(asset) < address(counterPartyToken)) {
            // asset是token0, counterPartyToken是token1
            amountAMin = (amount0 * slippageMultiplier) / BASIS_POINTS_DIVISOR;
            amountBMin = (amount1 * slippageMultiplier) / BASIS_POINTS_DIVISOR;
        } else {
            // asset是token1, counterPartyToken是token0
            amountAMin = (amount1 * slippageMultiplier) / BASIS_POINTS_DIVISOR;
            amountBMin = (amount0 * slippageMultiplier) / BASIS_POINTS_DIVISOR;
        }
    }

    /*//////////////////////////////////////////////////////////////
                               视图函数
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 计算 Uniswap LP Token 对应的底层资产价值
     * @param asset 底层资产代币
     * @return 底层资产价值
     */
    function getTotalValue(IERC20 asset) public view override returns (uint256) {
        TokenConfig memory config = getTokenConfig(asset);
        IUniswapV2Pair pair = config.pair;

        uint256 liquidityTokens = IERC20(address(pair)).balanceOf(address(this)); // 查询适配器的LP代币余额
        // 使用严格相等性检查是安全的，因为代币余额是整数值，不会有精度问题
        if (liquidityTokens == 0) return 0;

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();

        // 计算LP代币对应的两种资产数量
        uint256 amount0 = (uint256(reserve0) * liquidityTokens) / totalSupply;
        uint256 amount1 = (uint256(reserve1) * liquidityTokens) / totalSupply;

        // 返回正确的底层资产价值
        if (address(asset) == pair.token0()) {
            return amount0 + (amount1 * reserve0) / reserve1; // 将amount1(WETH)转换为底层资产
        } else {
            return amount1 + (amount0 * reserve1) / reserve0; // 将amount0(USDC)转换为底层资产
        }
    }

    /**
     * @notice 获取适配器名称
     * @return 适配器名称
     */
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
