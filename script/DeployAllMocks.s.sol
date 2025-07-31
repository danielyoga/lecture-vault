// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {MockWETH} from "../src/MockWETH.sol";
import {MockWBTC} from "../src/MockWBTC.sol";

contract DeployAllMocksScript is Script {
    MockUSDC public mockUSDC;
    MockWETH public mockWETH;
    MockWBTC public mockWBTC;
    
    function setUp() public {}

    function run() public {
        // Use Anvil's default private key
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        address router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        
        console.log("Deploying all mock tokens with address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy MockUSDC
        mockUSDC = new MockUSDC();
        console.log("MockUSDC deployed at:", address(mockUSDC));
        
        // Deploy MockWETH
        mockWETH = new MockWETH();
        console.log("MockWETH deployed at:", address(mockWETH));
        
        // Deploy MockWBTC
        mockWBTC = new MockWBTC();
        console.log("MockWBTC deployed at:", address(mockWBTC));
        
        // Mint tokens to deployer
        mockUSDC.mint(deployer, 1000000e6); // 1M USDC
        mockWETH.mint(deployer, 1000e18); // 1000 WETH
        mockWBTC.mint(deployer, 100e8); // 100 WBTC
        
        // Mint tokens to router for swap simulation
        mockUSDC.mint(router, 10000000e6); // 10M USDC to router
        mockWETH.mintToRouter(router, 10000e18); // 10K WETH to router
        mockWBTC.mintToRouter(router, 1000e8); // 1K WBTC to router
        
        vm.stopBroadcast();
        
        console.log("=== All Mock Tokens Deployment Complete ===");
        console.log("MockUSDC Address:", address(mockUSDC));
        console.log("MockWETH Address:", address(mockWETH));
        console.log("MockWBTC Address:", address(mockWBTC));
        console.log("");
        console.log("Deployer Balances:");
        console.log("- USDC:", mockUSDC.balanceOf(deployer));
        console.log("- WETH:", mockWETH.balanceOf(deployer));
        console.log("- WBTC:", mockWBTC.balanceOf(deployer));
        console.log("");
        console.log("Router Balances:");
        console.log("- USDC:", mockUSDC.balanceOf(router));
        console.log("- WETH:", mockWETH.balanceOf(router));
        console.log("- WBTC:", mockWBTC.balanceOf(router));
        console.log("");
        console.log("Update your Reksadana contract to use these addresses!");
    }
} 