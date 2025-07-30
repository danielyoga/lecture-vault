// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract MockUniswapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    
    // Mock exchange rates
    mapping(address => mapping(address => uint256)) public exchangeRates;
    
    constructor() {
        // Set default exchange rates for any token addresses
        // We'll set rates for any token pair that might be used
        _setDefaultRates();
    }
    
    function _setDefaultRates() internal {
        // USDC to WETH: 1 USDC = 0.0005 WETH (WETH price = $2000)
        exchangeRates[0xaf88d065e77c8cC2239327C5EDb3A432268e5831][0x82aF49447D8a07e3bd95BD0d56f35241523fBab1] = 500; // 0.0005 * 1e6
        
        // USDC to WBTC: 1 USDC = 0.000025 WBTC (WBTC price = $40000)
        exchangeRates[0xaf88d065e77c8cC2239327C5EDb3A432268e5831][0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f] = 25; // 0.000025 * 1e6
        
        // WETH to USDC: 1 WETH = 2000 USDC
        exchangeRates[0x82aF49447D8a07e3bd95BD0d56f35241523fBab1][0xaf88d065e77c8cC2239327C5EDb3A432268e5831] = 2000e6;
        
        // WBTC to USDC: 1 WBTC = 40000 USDC
        exchangeRates[0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f][0xaf88d065e77c8cC2239327C5EDb3A432268e5831] = 40000e6;
    }
    
    function exactInputSingle(ExactInputSingleParams calldata params) external returns (uint256 amountOut) {
        // Calculate amount out based on exchange rate
        uint256 rate = exchangeRates[params.tokenIn][params.tokenOut];
        
        // If rate not set, set a default rate
        if (rate == 0) {
            if (params.tokenOut == 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1) {
                // USDC to WETH
                rate = 500; // 0.0005 * 1e6
            } else if (params.tokenOut == 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f) {
                // USDC to WBTC
                rate = 25; // 0.000025 * 1e6
            } else if (params.tokenOut == 0xaf88d065e77c8cC2239327C5EDb3A432268e5831) {
                // WETH/WBTC to USDC
                rate = 2000e6;
            } else {
                // Default rate for any other token
                rate = 1000000; // 1:1 exchange
            }
            exchangeRates[params.tokenIn][params.tokenOut] = rate;
        }
        
        if (params.tokenOut == 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1) {
            // USDC to WETH
            amountOut = params.amountIn * rate / 1e6;
        } else if (params.tokenOut == 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f) {
            // USDC to WBTC
            amountOut = params.amountIn * rate / 1e6;
        } else if (params.tokenOut == 0xaf88d065e77c8cC2239327C5EDb3A432268e5831) {
            // WETH/WBTC to USDC
            amountOut = params.amountIn * rate / 1e18;
        } else {
            // Default calculation
            amountOut = params.amountIn * rate / 1e6;
        }
        
        // Transfer tokens
        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        IERC20(params.tokenOut).transfer(params.recipient, amountOut);
        
        return amountOut;
    }
    
    function setExchangeRate(address tokenIn, address tokenOut, uint256 rate) external {
        exchangeRates[tokenIn][tokenOut] = rate;
    }
} 