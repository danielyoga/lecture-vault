// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Reksadana} from "../src/Reksadana.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

contract ReksadanaScript is Script {
    Reksadana public reksadana;
    MockUSDC public mockUSDC;
    
    // Network addresses
    address public constant UNISWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address public constant BASE_FEED = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address public constant WBTC_FEED = 0x6ce185860a4963106506C203335A2910413708e9;
    address public constant WETH_FEED = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy MockUSDC first
        mockUSDC = new MockUSDC();
        console.log("MockUSDC deployed at:", address(mockUSDC));

        // Deploy Reksadana with deployer as manager
        reksadana = new Reksadana(
            UNISWAP_ROUTER,
            WETH,
            address(mockUSDC),
            WBTC,
            BASE_FEED,
            WBTC_FEED,
            WETH_FEED,
            deployer // deployer becomes the manager
        );
        console.log("Reksadana deployed at:", address(reksadana));
        
        // Log contract details
        console.log("=== Contract Details ===");
        console.log("Manager:", reksadana.manager());
        console.log("Owner:", reksadana.owner());
        console.log("Manager Fee:", reksadana.managerFee(), "(1%)");
        console.log("Performance Fee:", reksadana.performanceFee(), "(10%)");
        console.log("USDC Token:", reksadana.usdc());
        console.log("WETH Token:", reksadana.weth());
        console.log("WBTC Token:", reksadana.wbtc());
        console.log("Uniswap Router:", reksadana.uniswapRouter());
        
        vm.stopBroadcast();
        
        console.log("=== Deployment Complete ===");
        console.log("Update your frontend with these addresses:");
        console.log("REKSADANA:", address(reksadana));
        console.log("MOCK_USDC:", address(mockUSDC));
    }
} 