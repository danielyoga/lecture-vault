// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Reksadana} from "../src/Reksadana.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {MockWETH} from "../src/MockWETH.sol";
import {MockWBTC} from "../src/MockWBTC.sol";

contract DeployReksadanaWithMocksScript is Script {
    Reksadana public reksadana;
    MockUSDC public mockUSDC;
    MockWETH public mockWETH;
    MockWBTC public mockWBTC;
    
    function setUp() public {}

    function run() public {
        // Use Anvil's default private key
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        address router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        
        console.log("Deploying Reksadana with all mock tokens using address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy all mock tokens first
        mockUSDC = new MockUSDC();
        console.log("MockUSDC deployed at:", address(mockUSDC));
        
        mockWETH = new MockWETH();
        console.log("MockWETH deployed at:", address(mockWETH));
        
        mockWBTC = new MockWBTC();
        console.log("MockWBTC deployed at:", address(mockWBTC));
        
        // Mint tokens to deployer and router
        mockUSDC.mint(deployer, 1000000e6); // 1M USDC
        mockWETH.mint(deployer, 1000e18); // 1000 WETH
        mockWBTC.mint(deployer, 100e8); // 100 WBTC
        
        mockUSDC.mint(router, 10000000e6); // 10M USDC to router
        mockWETH.mintToRouter(router, 10000e18); // 10K WETH to router
        mockWBTC.mintToRouter(router, 1000e8); // 1K WBTC to router
        
        // Deploy Reksadana with mock token addresses
        reksadana = new Reksadana(
            router, // Uniswap Router
            address(mockWETH), // WETH (using our mock)
            address(mockUSDC), // USDC (using our mock)
            address(mockWBTC), // WBTC (using our mock)
            0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3, // BASE_FEED (keeping original)
            0x6ce185860a4963106506C203335A2910413708e9, // WBTC_FEED (keeping original)
            0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612, // WETH_FEED (keeping original)
            deployer // deployer becomes the manager
        );
        console.log("Reksadana deployed at:", address(reksadana));
        
        vm.stopBroadcast();
        
        console.log("=== Deployment Complete ===");
        console.log("Contract Addresses:");
        console.log("- Reksadana:", address(reksadana));
        console.log("- MockUSDC:", address(mockUSDC));
        console.log("- MockWETH:", address(mockWETH));
        console.log("- MockWBTC:", address(mockWBTC));
        console.log("");
        console.log("Deployer Balances:");
        console.log("- USDC:", mockUSDC.balanceOf(deployer));
        console.log("- WETH:", mockWETH.balanceOf(deployer));
        console.log("- WBTC:", mockWBTC.balanceOf(deployer));
        console.log("");
        console.log("Reksadana Contract Details:");
        console.log("- Manager:", reksadana.manager());
        console.log("- Owner:", reksadana.owner());
        console.log("- Manager Fee:", reksadana.managerFee(), "(1%)");
        console.log("- Performance Fee:", reksadana.performanceFee(), "(10%)");
        console.log("");
        console.log("Update your frontend with these addresses!");
    }
} 