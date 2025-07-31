// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MockWETH} from "../src/MockWETH.sol";

contract DeployMockWETHScript is Script {
    MockWETH public mockWETH;
    
    function setUp() public {}

    function run() public {
        // Use Anvil's default private key
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying MockWETH with address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy MockWETH
        mockWETH = new MockWETH();
        console.log("MockWETH deployed at:", address(mockWETH));
        
        // Mint some WETH to deployer for testing
        mockWETH.mint(deployer, 1000e18); // 1000 WETH
        console.log("Minted 1000 WETH to deployer");
        
        // Mint some WETH to router address for swap simulation
        address router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        mockWETH.mintToRouter(router, 10000e18); // 10000 WETH to router
        console.log("Minted 10000 WETH to router for swap simulation");
        
        vm.stopBroadcast();
        
        console.log("=== MockWETH Deployment Complete ===");
        console.log("MockWETH Address:", address(mockWETH));
        console.log("Deployer Balance:", mockWETH.balanceOf(deployer));
        console.log("Router Balance:", mockWETH.balanceOf(router));
        console.log("Update your Reksadana contract to use this WETH address!");
    }
} 