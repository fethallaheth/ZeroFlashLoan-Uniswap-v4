#  ZeroFlashLoan

A Solidity smart contract for executing zero-fee flash loans using Uniswap v4's PoolManager on the Base chain. This contract leverages the `unlock` mechanism and `IUnlockCallback` to borrow tokens (e.g., USDC) from the pool manager, perform operations, and repay within the same transaction without fees, assuming no protocol fees are applied.

## Why Use Uniswap V4?

- **Centralized Liquidity Access**: In Uniswap V4, the PoolManager aggregates liquidity from all pools, allowing flash loans up to the total token reserves across the entire protocol, unlike V3 where loans are limited to individual pool reserves.
- **Zero Fees**: Flash loans in V4 incur no protocol fees by default, making them cost-effective for arbitrage, liquidations, or other atomic operations (custom pool fees may still apply if configured).

## How It Works (Logic Flow)

1. **Initiate Flash Loan**: The user calls `flashLoan(Currency currency, uint256 amount)` on the `ZeroFlashLoan` contract, which encodes the borrower, currency, and amount, then invokes `poolManager.unlock(unlockData)` to start the callback.

2. **Unlock Callback**: The PoolManager calls back to `unlockCallback(bytes calldata data)` on the contract. This verifies the caller (onlyPoolManager modifier), checks sufficient funds in the PoolManager, uses `take(currency, borrower, amount)` to transfer the borrowed amount to the borrower, and syncs the currency state.

3. **User Logic**: At this point, the borrower receives the funds and can execute arbitrary logic (e.g., swaps, arbitrage). In this basic implementation, no additional logic is performed—funds are immediately prepared for repayment.

4. **Repay and Settle**: The callback then repays the exact amount: For ERC20 tokens, it uses `safeTransferFrom(borrower, poolManager, amount)` (requires prior approval); for native ETH, it settles with value. Finally, `poolManager.settle()` is called to balance the protocol's accounting, ensuring atomicity—if repayment fails, the transaction reverts.

This ensures the PoolManager's balance is restored by the end of the transaction, with no net change.

## Features

- Flash loan initiation via `flashLoan(Currency currency, uint256 amount)`.
- Secure callback handling with `onlyPoolManager` modifier.
- Support for ERC20 tokens And Native Tokens as well.
- Built with Foundry for testing on a forked Base chain.

## Prerequisites

- [Rust](https://www.rust-lang.org/tools/install) (for Foundry).
- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed.
- Access to Blockchain RPC (e.g., via Alchemy or Infura).

## Installation

1. Clone the repository:

   ```shell
   git clone <>
   cd ZeroFlashLoan
   ```

2. Install dependencies:

   ```shell
   forge install foundry-rs/forge-std@v1.9.1
   forge install Uniswap/v4-core
   ```

3. Update remappings if needed (check `remappings.txt`).

## Project Structure

- `src/`: Core contracts (e.g., `ZeroFlashLoan.sol`).
- `test/`: Foundry tests (e.g., `ZeroFlashLoan.t.sol` for flash loan simulations).
- `script/`: Deployment scripts (e.g., `ZeroFlashLoan.s.sol`).
- `foundry.toml`: Foundry configuration.

## Running Tests

Tests use a forked Base chain at block 34435600 for reproducibility.

1. Build the project:

   ```shell
   forge build
   ```

2. Run all tests:

   ```shell
   forge test
   ```

3. Run specific test with verbose output:

   ```shell
   forge test --match-test test_flashLoan -vv
   ```

4. Format code:

   ```shell
   forge fmt
   ```

## Deployment

1. Update the `POOL_MANAGER` address in tests/scripts to your target deployment (current: Base mainnet PoolManager at `0x498581fF718922c3f8e6A244956aF099B2652b2b`).

2. Deploy using Foundry script:

   ```shell
   forge script script/ZeroFlashLoan.s.sol:ZeroFlashLoanScript --rpc-url $BASE_RPC_URL --private-key $PRIVATE_KEY --broadcast
   ```

   - Set `BASE_RPC_URL` to your Base RPC endpoint.
   - Set `PRIVATE_KEY` to your deployer wallet's private key.

3. Verify on Basescan (if deployed to mainnet).


## Contributing

Fork the repo, create a branch, make changes, and submit a PR.

## License

UNLICENSED
