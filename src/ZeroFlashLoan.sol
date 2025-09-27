// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUnlockCallback} from "v4-core/interfaces/callback/IUnlockCallback.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {CurrencyLibrary} from "v4-core/types/Currency.sol";

/// @title ZeroFlashLoan
/// @author ChoasSR
contract ZeroFlashLoan is IUnlockCallback {
    using SafeERC20 for IERC20;
    using CurrencyLibrary for Currency;

    /// @notice Emitted when the caller is not authorized (must be the PoolManager).
    error Unauthorized();
    /// @notice Emitted when the requested loan amount exceeds available funds in the PoolManager.
    error InsufficientFunds();

    /// @notice The immutable reference to the Uniswap V4 PoolManager contract.
    IPoolManager public immutable poolManager;

    /// @param _poolManager The address of the Uniswap V4 PoolManager.
    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
    }

    /// @notice Modifier to ensure only the PoolManager can call the function.
    /// @dev Reverts with Unauthorized if msg.sender is not poolManager.
    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert Unauthorized();
        _;
    }

    /// @notice Initiates a flash loan by unlocking the PoolManager and triggering the callback.
    /// @dev Encodes borrower details and calls poolManager.unlock(). The callback will handle taking and settling funds.
    /// @param _currency The Currency (token or ETH) to borrow.
    /// @param _amount The amount to borrow in the currency's smallest unit.
    function flashLoan(Currency _currency, uint256 _amount) external {
        bytes memory unlockData = abi.encode(msg.sender, _currency, _amount);
        poolManager.unlock(unlockData);
    }

    /// @notice Callback function invoked by the PoolManager during unlock.
    /// @dev Decodes data, checks funds, takes the amount to borrower, syncs state, and settles repayment.
    ///      For ERC20: Uses safeTransferFrom (requires approval). For ETH: Settles with value.
    ///      This basic implementation repays immediately; override or extend for user logic.
    /// @param data Encoded bytes: (borrower address, Currency, amount).
    /// @return Empty bytes as no delta is computed here (basic repayment).
    function unlockCallback(bytes calldata data) external onlyPoolManager returns (bytes memory) {
        (address borrower, Currency currency, uint256 amount) = abi.decode(data, (address, Currency, uint256));

        uint256 funds = currency.isAddressZero()
            ? address(poolManager).balance
            : IERC20(Currency.unwrap(currency)).balanceOf(address(poolManager));

        if (amount > funds) revert InsufficientFunds();

        poolManager.take(currency, borrower, amount);

        poolManager.sync(currency);

        if (currency.isAddressZero()) {
            poolManager.settle{value: amount}();
        } else {
            IERC20(Currency.unwrap(currency)).safeTransferFrom(borrower, address(poolManager), amount);
            poolManager.settle();
        }

        return "";
    }

    receive() external payable {}
}
