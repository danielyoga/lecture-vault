// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Vault} from "../src/Vault.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

contract VaultScript is Script {
    Vault public vault;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        MockUSDC usdc = new MockUSDC();
        
        vault = new Vault(address(usdc));

        console.log("Vault deployed at:", address(vault));
        console.log("USDC address used:", address(usdc));

        vm.stopBroadcast();
    }
}