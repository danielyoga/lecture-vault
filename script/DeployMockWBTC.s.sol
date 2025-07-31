// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MockWBTC} from "../src/MockWBTC.sol";

contract DeployMockWBTCScript is Script {
    MockWBTC public mockWBTC;
    
    function setUp() public {}

    function run() public {
        // Use Anvil's default private key
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying MockWBTC with address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy MockWBTC
        mockWBTC = new MockWBTC();
        console.log("MockWBTC deployed at:", address(mockWBTC));
        
        // Mint some WBTC to deployer for testing
        mockWBTC.mint(deployer, 100e8); // 100 WBTC (8 decimals)
        console.log("Minted 100 WBTC to deployer");
        
        // Mint some WBTC to router address for swap simulation
        address router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        mockWBTC.mintToRouter(router, 1000e8); // 1000 WBTC to router
        console.log("Minted 1000 WBTC to router for swap simulation");
        
        vm.stopBroadcast();
        
        console.log("=== MockWBTC Deployment Complete ===");
        console.log("MockWBTC Address:", address(mockWBTC));
        console.log("Deployer Balance:", mockWBTC.balanceOf(deployer));
        console.log("Router Balance:", mockWBTC.balanceOf(router));
        console.log("Update your Reksadana contract to use this WBTC address!");
    }
} 