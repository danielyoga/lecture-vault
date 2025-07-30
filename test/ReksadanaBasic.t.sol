// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Reksadana} from "../src/Reksadana.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ReksadanaBasicTest is Test {
    Reksadana public reksadana;
    MockUSDC public mockUSDC;
    
    // Test addresses
    address public constant UNISWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address public constant BASE_FEED = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address public constant WBTC_FEED = 0x6ce185860a4963106506C203335A2910413708e9;
    address public constant WETH_FEED = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
    
    address public manager;
    address public user1;
    address public user2;
    
    uint256 public constant DEPOSIT_AMOUNT = 1000e6; // 1000 USDC

    function setUp() public {
        // Create test accounts
        manager = makeAddr("manager");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Deploy MockUSDC
        mockUSDC = new MockUSDC();
        
        // Deploy Reksadana with manager
        vm.prank(manager);
        reksadana = new Reksadana(
            UNISWAP_ROUTER,
            WETH,
            address(mockUSDC),
            WBTC,
            BASE_FEED,
            WBTC_FEED,
            WETH_FEED,
            manager
        );
        
        // Mint USDC to users
        mockUSDC.mint(user1, 10000e6); // 10,000 USDC
        mockUSDC.mint(user2, 10000e6); // 10,000 USDC
        mockUSDC.mint(manager, 1000e6); // 1,000 USDC
    }

    // ========== BASIC CONSTRUCTOR TESTS ==========
    
    function testConstructor() public view {
        assertEq(reksadana.uniswapRouter(), UNISWAP_ROUTER);
        assertEq(reksadana.weth(), WETH);
        assertEq(reksadana.usdc(), address(mockUSDC));
        assertEq(reksadana.wbtc(), WBTC);
        assertEq(reksadana.manager(), manager);
        assertEq(reksadana.owner(), manager);
        assertEq(reksadana.managerFee(), 100); // 1%
        assertEq(reksadana.performanceFee(), 1000); // 10%
    }

    // ========== MANAGER FEE TESTS ==========
    
    function testSetManagerFee() public {
        uint256 newFee = 200; // 2%
        
        vm.prank(manager);
        reksadana.setManagerFee(newFee);
        
        assertEq(reksadana.managerFee(), newFee);
    }
    
    function testSetManagerFeeTooHigh() public {
        uint256 tooHighFee = 600; // 6% > 5% max
        
        vm.prank(manager);
        vm.expectRevert(Reksadana.InvalidFee.selector);
        reksadana.setManagerFee(tooHighFee);
    }
    
    function testSetManagerFeeUnauthorized() public {
        vm.prank(user1);
        vm.expectRevert(Reksadana.Unauthorized.selector);
        reksadana.setManagerFee(200);
    }

    // ========== PERFORMANCE FEE TESTS ==========
    
    function testSetPerformanceFee() public {
        uint256 newFee = 1500; // 15%
        
        vm.prank(manager);
        reksadana.setPerformanceFee(newFee);
        
        assertEq(reksadana.performanceFee(), newFee);
    }
    
    function testSetPerformanceFeeTooHigh() public {
        uint256 tooHighFee = 2500; // 25% > 20% max
        
        vm.prank(manager);
        vm.expectRevert(Reksadana.InvalidFee.selector);
        reksadana.setPerformanceFee(tooHighFee);
    }

    // ========== MANAGER TESTS ==========
    
    function testSetManager() public {
        address newManager = makeAddr("newManager");
        
        vm.prank(manager);
        reksadana.setManager(newManager);
        
        assertEq(reksadana.manager(), newManager);
    }
    
    function testSetManagerInvalidAddress() public {
        vm.prank(manager);
        vm.expectRevert(Reksadana.InvalidManager.selector);
        reksadana.setManager(address(0));
    }
    
    function testSetManagerUnauthorized() public {
        address newManager = makeAddr("newManager");
        
        vm.prank(user1);
        vm.expectRevert(); // Ownable revert
        reksadana.setManager(newManager);
    }

    // ========== VIEW FUNCTION TESTS ==========
    
    function testGetManagerFee() public view {
        assertEq(reksadana.getManagerFee(), 100);
    }
    
    function testGetPerformanceFee() public view {
        assertEq(reksadana.getPerformanceFee(), 1000);
    }
    
    function testGetManager() public view {
        assertEq(reksadana.getManager(), manager);
    }
    
    function testGetLastTotalAssetValue() public {
        assertEq(reksadana.getLastTotalAssetValue(), 0);
        
        // We can't call updateLastTotalAssetValue() because it calls totalAsset()
        // which requires external price feeds. Let's just test the initial value.
        assertEq(reksadana.getLastTotalAssetValue(), 0);
    }

    // ========== ERROR TESTS ==========
    
    function testDepositZeroAmount() public {
        vm.startPrank(user1);
        mockUSDC.approve(address(reksadana), 0);
        
        vm.expectRevert(Reksadana.ZeroAmount.selector);
        reksadana.deposit(0);
        
        vm.stopPrank();
    }
    
    function testWithdrawZeroShares() public {
        vm.startPrank(user1);
        
        vm.expectRevert(Reksadana.ZeroAmount.selector);
        reksadana.withdraw(0);
        
        vm.stopPrank();
    }
    
    function testWithdrawInsufficientShares() public {
        vm.startPrank(user1);
        
        vm.expectRevert(Reksadana.InsufficientShares.selector);
        reksadana.withdraw(1000e18); // Try to withdraw more than owned
        
        vm.stopPrank();
    }

    // ========== EVENT TESTS ==========
    
    function testManagerFeeUpdatedEvent() public {
        uint256 newFee = 200;
        
        vm.prank(manager);
        vm.expectEmit(false, false, false, true);
        emit Reksadana.ManagerFeeUpdated(100, newFee);
        reksadana.setManagerFee(newFee);
    }
    
    function testManagerUpdatedEvent() public {
        address newManager = makeAddr("newManager");
        
        vm.prank(manager);
        vm.expectEmit(true, true, false, false);
        emit Reksadana.ManagerUpdated(manager, newManager);
        reksadana.setManager(newManager);
    }

    // ========== CONSTANT TESTS ==========
    
    function testConstants() public view {
        assertEq(reksadana.FEE_DENOMINATOR(), 10000);
        assertEq(reksadana.MAX_MANAGER_FEE(), 500);
        assertEq(reksadana.MAX_PERFORMANCE_FEE(), 2000);
    }
} 