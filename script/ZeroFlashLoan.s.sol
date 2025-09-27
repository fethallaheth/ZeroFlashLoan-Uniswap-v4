// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ZeroFlashLoan} from "../src/ZeroFlashLoan.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

contract ZeroFlashLoanScript is Script {
    ZeroFlashLoan public zeroflashloan;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        zeroflashloan = new ZeroFlashLoan(IPoolManager(0x498581fF718922c3f8e6A244956aF099B2652b2b));
        console.log("ZeroFlashLoan deployed at:", address(zeroflashloan));

        vm.stopBroadcast();
    }
}
