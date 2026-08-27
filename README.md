# Simple AMM — Solidity

A security-focused educational implementation of a constant-product Automated Market Maker (AMM) written in Solidity.

The project implements liquidity provision, LP tokens, token swaps, a 0.3% swap fee, slippage protection, transaction deadlines, reentrancy protection, fuzz testing, and invariant testing.

## Features

- Constant-product AMM (`x * y = k`)
- Two ERC20 token pool
- 0.3% swap fee
- LP token minting
- LP token burning
- `MINIMUM_LIQUIDITY` lock
- Slippage protection
- Transaction deadline protection
- Custom Solidity errors
- Reentrancy protection
- Checks-Effects-Interactions pattern
- Explicit reserve accounting
- Safe ERC20 transfer handling
- Fuzz testing
- Invariant testing
- Foundry-based development and testing

## Project Structure

```text
simple-amm-solidity/
├── src/
│   ├── IERC20.sol
│   ├── MockERC20.sol
│   └── SimpleAMM.sol
│
├── test/
│   ├── SetupTest.t.sol
│   ├── AddLiquidityTest.t.sol
│   ├── SwapTest.t.sol
│   ├── RemoveLiquidityTest.t.sol
│   ├── FuzzBoundsTest.t.sol
│   ├── Handler.sol
│   └── InvariantTest.t.sol
│
├── lib/
├── foundry.toml
├── .gitignore
└── README.md