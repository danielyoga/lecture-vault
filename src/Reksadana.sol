// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ISwapRouter} from "../lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract Reksadana is ERC20, Ownable {
    // Constants
    uint256 public constant FEE_DENOMINATOR = 10000; // 100% = 10000
    uint256 public constant MAX_MANAGER_FEE = 500; // 5% max fee
    uint256 public constant MAX_PERFORMANCE_FEE = 2000; // 20% max performance fee
    
    // State variables
    address public immutable uniswapRouter;
    address public immutable weth;
    address public immutable usdc;
    address public immutable wbtc;
    
    address public immutable baseFeed;
    address public immutable wbtcFeed;
    address public immutable wethFeed;
    
    // Fee configuration
    uint256 public managerFee = 100; // 1% default
    uint256 public performanceFee = 1000; // 10% default
    uint256 public lastTotalAssetValue;
    uint256 public accumulatedFees;
    
    // Manager address
    address public manager;
    
    // Events
    event Deposit(address indexed user, uint256 amount, uint256 shares, uint256 fee);
    event Withdraw(address indexed user, uint256 shares, uint256 amount, uint256 fee);
    event ManagerFeeCollected(address indexed manager, uint256 amount);
    event PerformanceFeeCollected(address indexed manager, uint256 amount);
    event ManagerFeeUpdated(uint256 oldFee, uint256 newFee);
    event PerformanceFeeUpdated(uint256 oldFee, uint256 newFee);
    event ManagerUpdated(address indexed oldManager, address indexed newManager);
    
    // Errors
    error ZeroAmount();
    error InsufficientShares();
    error InvalidFee();
    error InvalidManager();
    error Unauthorized();

    constructor(
        address _uniswapRouter,
        address _weth,
        address _usdc,
        address _wbtc,
        address _baseFeed,
        address _wbtcFeed,
        address _wethFeed,
        address _manager
    ) ERC20("Reksadana", "RKS") Ownable(msg.sender) {
        uniswapRouter = _uniswapRouter;
        weth = _weth;
        usdc = _usdc;
        wbtc = _wbtc;
        baseFeed = _baseFeed;
        wbtcFeed = _wbtcFeed;
        wethFeed = _wethFeed;
        manager = _manager;
    }

    // Modifiers
    modifier onlyManager() {
        if (msg.sender != manager && msg.sender != owner()) {
            revert Unauthorized();
        }
        _;
    }

    // Total asset value in USDC terms
    function totalAsset() public view returns (uint256) {
        // Get USDC price in USD
        (, int256 usdcPrice,,,) = AggregatorV3Interface(baseFeed).latestRoundData();

        // Get WBTC price in USD
        (, int256 wbtcPrice,,,) = AggregatorV3Interface(wbtcFeed).latestRoundData();
        uint256 wbtcPriceInUSD = uint256(wbtcPrice) * 1e6 / uint256(usdcPrice);

        // Get WETH price in USD
        (, int256 wethPrice,,,) = AggregatorV3Interface(wethFeed).latestRoundData();
        uint256 wethPriceInUSD = uint256(wethPrice) * 1e6 / uint256(usdcPrice);

        // Calculate total asset value
        uint256 totalWethAsset = IERC20(weth).balanceOf(address(this)) * wethPriceInUSD / 1e18;
        uint256 totalWbtcAsset = IERC20(wbtc).balanceOf(address(this)) * wbtcPriceInUSD / 1e8;

        return totalWethAsset + totalWbtcAsset;
    }

    // Deposit function with manager fee
    function deposit(uint256 amount) external {
        if (amount == 0) {
            revert ZeroAmount();
        }
        
        uint256 totalAssetValue = totalAsset();
        uint256 totalShares = totalSupply();
        
        // Calculate manager fee
        uint256 managerFeeAmount = amount * managerFee / FEE_DENOMINATOR;
        uint256 depositAmount = amount - managerFeeAmount;
        
        // Calculate shares
        uint256 shares = 0;
        if (totalShares == 0) {
            shares = depositAmount;
        } else {
            shares = depositAmount * totalShares / totalAssetValue;
        }

        // Transfer USDC from user
        IERC20(usdc).transferFrom(msg.sender, address(this), amount);
        
        // Mint shares to user
        _mint(msg.sender, shares);
        
        // Send manager fee to manager
        if (managerFeeAmount > 0) {
            IERC20(usdc).transfer(manager, managerFeeAmount);
            emit ManagerFeeCollected(manager, managerFeeAmount);
        }
        
        // Invest remaining amount
        _investAssets(depositAmount);
        
        emit Deposit(msg.sender, amount, shares, managerFeeAmount);
    }

    // Withdraw function with performance fee
    function withdraw(uint256 shares) external {
        if (shares == 0) {
            revert ZeroAmount();
        }
        if (balanceOf(msg.sender) < shares) {
            revert InsufficientShares();
        }

        uint256 totalShares = totalSupply();
        uint256 proportion = shares * 1e18 / totalShares;
        
        // Calculate assets to withdraw
        uint256 wbtcToSell = IERC20(wbtc).balanceOf(address(this)) * proportion / 1e18;
        uint256 wethToSell = IERC20(weth).balanceOf(address(this)) * proportion / 1e18;
        
        // Burn shares
        _burn(msg.sender, shares);
        
        // Convert assets to USDC
        uint256 usdcAmount = _convertAssetsToUSDC(wbtcToSell, wethToSell);
        
        // Calculate performance fee if there's profit
        uint256 performanceFeeAmount = 0;
        if (lastTotalAssetValue > 0) {
            uint256 currentValue = totalAsset();
            if (currentValue > lastTotalAssetValue) {
                uint256 profit = currentValue - lastTotalAssetValue;
                performanceFeeAmount = profit * performanceFee / FEE_DENOMINATOR;
            }
        }
        
        uint256 withdrawAmount = usdcAmount - performanceFeeAmount;
        
        // Transfer USDC to user
        IERC20(usdc).transfer(msg.sender, withdrawAmount);
        
        // Transfer performance fee to manager
        if (performanceFeeAmount > 0) {
            IERC20(usdc).transfer(manager, performanceFeeAmount);
            emit PerformanceFeeCollected(manager, performanceFeeAmount);
        }
        
        emit Withdraw(msg.sender, shares, withdrawAmount, performanceFeeAmount);
    }

    // Internal function to invest assets
    function _investAssets(uint256 amount) internal {
        uint256 amountIn = amount / 2;
        
        // Convert half to WETH
        IERC20(usdc).approve(uniswapRouter, amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: usdc,
            tokenOut: weth,
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        ISwapRouter(uniswapRouter).exactInputSingle(params);
        
        // Convert half to WBTC
        IERC20(usdc).approve(uniswapRouter, amountIn);
        params = ISwapRouter.ExactInputSingleParams({
            tokenIn: usdc,
            tokenOut: wbtc,
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        ISwapRouter(uniswapRouter).exactInputSingle(params);
    }

    // Internal function to convert assets to USDC
    function _convertAssetsToUSDC(uint256 wbtcAmount, uint256 wethAmount) internal returns (uint256) {
        uint256 totalUsdc = 0;
        
        // Convert WBTC to USDC
        if (wbtcAmount > 0) {
            IERC20(wbtc).approve(uniswapRouter, wbtcAmount);
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: wbtc,
                tokenOut: usdc,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: wbtcAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            ISwapRouter(uniswapRouter).exactInputSingle(params);
        }
        
        // Convert WETH to USDC
        if (wethAmount > 0) {
            IERC20(weth).approve(uniswapRouter, wethAmount);
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: weth,
                tokenOut: usdc,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: wethAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            ISwapRouter(uniswapRouter).exactInputSingle(params);
        }
        
        return IERC20(usdc).balanceOf(address(this));
    }

    // Manager functions
    function setManagerFee(uint256 newFee) external onlyManager {
        if (newFee > MAX_MANAGER_FEE) {
            revert InvalidFee();
        }
        uint256 oldFee = managerFee;
        managerFee = newFee;
        emit ManagerFeeUpdated(oldFee, newFee);
    }

    function setPerformanceFee(uint256 newFee) external onlyManager {
        if (newFee > MAX_PERFORMANCE_FEE) {
            revert InvalidFee();
        }
        uint256 oldFee = performanceFee;
        performanceFee = newFee;
        emit PerformanceFeeUpdated(oldFee, newFee);
    }

    function setManager(address newManager) external onlyOwner {
        if (newManager == address(0)) {
            revert InvalidManager();
        }
        address oldManager = manager;
        manager = newManager;
        emit ManagerUpdated(oldManager, newManager);
    }

    function updateLastTotalAssetValue() external onlyManager {
        lastTotalAssetValue = totalAsset();
    }

    // View functions
    function getManagerFee() external view returns (uint256) {
        return managerFee;
    }

    function getPerformanceFee() external view returns (uint256) {
        return performanceFee;
    }

    function getManager() external view returns (address) {
        return manager;
    }

    function getLastTotalAssetValue() external view returns (uint256) {
        return lastTotalAssetValue;
    }
}