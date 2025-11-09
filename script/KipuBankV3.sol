// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {KipuBank} from "../src/KipuBankV3.sol";

contract KipuBankScript is Script {
    KipuBank public kipuBank;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        kipuBank = new KipuBank(10000000000, 1000000000, 0x694AA1769357215DE4FAC081bf1f309aDC325306, 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238, 0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3);

        vm.stopBroadcast();
    }
}
