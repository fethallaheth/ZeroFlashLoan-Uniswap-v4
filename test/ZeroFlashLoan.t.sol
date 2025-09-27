// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {console, Test} from "forge-std/Test.sol";

import {ZeroFlashLoan} from "../src/ZeroFlashLoan.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Currency} from "v4-core/types/Currency.sol";

contract ZeroFlashLoanTest is Test {
    address constant POOL_MANAGER = 0x498581fF718922c3f8e6A244956aF099B2652b2b;

    ZeroFlashLoan zeroFlashLoan;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("base"), 34435600);
        zeroFlashLoan = new ZeroFlashLoan(IPoolManager(POOL_MANAGER));
    }

    function test_flashLoan() public {
        assertEq(block.number, 34435600);
        // Define the token and amount for the flash loan
        address token = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC flash loan// Actual balance at this block
        Currency currency = Currency.wrap(token);

        uint256 funds = IERC20(token).balanceOf(POOL_MANAGER);
        console.log("PoolManager's initial balance:", funds);

        uint256 amount = 10 * 10 ** 6;
        uint256 balanceBefore = IERC20(token).balanceOf(address(msg.sender));
        console.log("before balance is :", balanceBefore);
        // Initiate the flash loan
        IERC20(token).approve(address(zeroFlashLoan), amount);
        zeroFlashLoan.flashLoan(currency, amount);
        uint256 BalanceAfter = IERC20(token).balanceOf(address(msg.sender));
        console.log("After balance is :", BalanceAfter);

        // Verify that the PoolManager's balance is restored
        vm.assertEq(IERC20(token).balanceOf(POOL_MANAGER), funds);
    }
}
