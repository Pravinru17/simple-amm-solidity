# SimpleAMM — Constant Product AMM in Solidity

A security-focused educational implementation of a **constant-product Automated Market Maker (AMM)** written in **Solidity 0.8.20** and tested extensively using **Foundry**.

The project implements core AMM mechanics inspired by the design of Uniswap V2, including:

* Liquidity provision
* LP token accounting
* Liquidity withdrawal
* Token swaps
* Constant-product pricing
* 0.3% swap fee
* Slippage protection
* Transaction deadlines
* Reserve accounting
* Minimum liquidity locking
* Reentrancy protection
* Fuzz testing
* Stateful invariant testing

> **Educational project:** This implementation is intended for Solidity, DeFi, and smart-contract security learning. It has not been independently audited and should not be used with real funds.

---

# Overview

SimpleAMM is a two-token automated market maker based on the constant-product model:

```text
x * y = k
```

where:

* `x` = reserve of token0
* `y` = reserve of token1
* `k` = constant-product invariant

Liquidity providers deposit both tokens into the pool and receive LP tokens representing their share of the pool.

Traders can swap token0 for token1 or token1 for token0.

---

# AMM Architecture

```text
                 SimpleAMM
                     │
       ┌─────────────┼─────────────┐
       │             │             │
       ▼             ▼             ▼
   Token0         Reserves       Token1
       │             │             │
       └─────────────┼─────────────┘
                     │
              LP Token Accounting
                     │
       ┌─────────────┴─────────────┐
       ▼                           ▼
Add Liquidity                 Remove Liquidity
       │
       ▼
     Swap
```

The contract tracks:

```solidity
uint256 public reserve0;
uint256 public reserve1;
```

These represent the AMM's explicitly tracked token reserves.

---

# Core AMM Formula

The pool follows the constant-product model:

```text
reserve0 * reserve1 = k
```

For a swap from token0 to token1:

```text
amountOut =
    (amountInWithFee * reserveOut)
    /
    (reserveIn * 1000 + amountInWithFee)
```

The implementation applies a **0.3% fee** using:

```solidity
uint256 public constant FEE_NUMERATOR = 997;
uint256 public constant FEE_DENOMINATOR = 1000;
```

Therefore:

```text
amountInWithFee = amountIn × 997
```

The fee remains in the pool and contributes to the growth of `k`.

---

# Features

* Two-token constant-product AMM
* `token0` / `token1` pair
* Explicit reserve accounting
* Liquidity provision
* Liquidity withdrawal
* LP token minting
* LP token burning
* Minimum liquidity lock
* Token0 → Token1 swaps
* Token1 → Token0 swaps
* 0.3% swap fee
* Slippage protection
* Transaction deadline protection
* Reentrancy protection
* Custom Solidity errors
* Safe ERC-20 interaction
* Fuzz testing
* Stateful invariant testing
* Reserve accounting tests
* Constant-product testing
* LP accounting tests

---

# Tech Stack

* **Solidity:** `^0.8.20`
* **Testing:** Foundry / Forge
* **Local Blockchain:** Anvil
* **Language:** Solidity
* **Version Control:** Git / GitHub

---

# Contract Structure

```text
SimpleAMM
│
├── Token Pair
│   ├── token0
│   └── token1
│
├── Reserves
│   ├── reserve0
│   └── reserve1
│
├── LP Token
│   ├── totalSupply
│   ├── balanceOf
│   └── allowance
│
├── Liquidity
│   ├── addLiquidity()
│   └── removeLiquidity()
│
├── Trading
│   └── swap()
│
└── Internal Accounting
    ├── _update()
    ├── _mint()
    ├── _burn()
    ├── _safeTransfer()
    └── _safeTransferFrom()
```

---

# Token Pair

The constructor accepts two ERC-20 token addresses:

```solidity
constructor(
    address _token0,
    address _token1
)
```

The constructor rejects:

* Zero addresses
* Identical token addresses

This prevents an invalid token pair from being created.

---

# Reserves

The AMM explicitly tracks:

```solidity
uint256 public reserve0;
uint256 public reserve1;
```

The reserves are updated after liquidity operations and swaps.

The contract intentionally tracks reserves separately rather than using token balances as the primary accounting state.

---

# Liquidity Provision

Liquidity providers use:

```solidity
addLiquidity()
```

to deposit both tokens into the pool.

The function accepts:

```solidity
function addLiquidity(
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min,
    uint256 deadline
)
```

The parameters provide:

* Desired token0 amount
* Desired token1 amount
* Minimum acceptable token0 amount
* Minimum acceptable token1 amount
* Transaction deadline

---

# First Liquidity Deposit

For the first liquidity provider, the AMM calculates LP tokens using:

```text
sqrt(amount0 × amount1)
```

The implementation locks a minimum amount of liquidity:

```solidity
uint256 public constant MINIMUM_LIQUIDITY = 1000;
```

The initial LP token calculation is:

```text
liquidity = sqrt(amount0 × amount1)
            - MINIMUM_LIQUIDITY
```

The minimum liquidity is permanently assigned to:

```text
address(0)
```

This prevents the pool from being completely emptied of liquidity.

---

# Subsequent Liquidity Deposits

For an existing pool, liquidity is calculated according to the current reserve ratio.

The contract calculates optimal token amounts so that liquidity providers do not unintentionally deposit tokens in an incorrect ratio.

For example:

```text
Current pool:

1000 Token0
1000 Token1
```

If a user wants to deposit:

```text
2000 Token0
1000 Token1
```

the AMM only uses the amount required to maintain the pool ratio.

This prevents unnecessary token deposits.

---

# Liquidity Token Accounting

LP tokens are represented using:

```solidity
uint256 public totalSupply;

mapping(address => uint256)
    public balanceOf;
```

When liquidity is added:

```text
Tokens deposited
       ↓
LP tokens minted
```

When liquidity is removed:

```text
LP tokens burned
       ↓
Underlying tokens returned
```

---

# Removing Liquidity

Liquidity providers use:

```solidity
removeLiquidity()
```

to withdraw their proportional share of the pool.

The function accepts:

```solidity
function removeLiquidity(
    uint256 liquidity,
    uint256 amount0Min,
    uint256 amount1Min,
    uint256 deadline
)
```

The user's share is calculated using:

```text
amount0 =
    liquidity × reserve0
    /
    totalSupply
```

and:

```text
amount1 =
    liquidity × reserve1
    /
    totalSupply
```

The corresponding LP tokens are then burned.

---

# Swap

The AMM supports both directions:

```text
Token0 → Token1
```

and:

```text
Token1 → Token0
```

The swap function is:

```solidity
function swap(
    uint256 amountIn,
    bool zeroForOne,
    uint256 amountOutMin,
    uint256 deadline
)
```

Where:

```text
zeroForOne = true
```

means:

```text
Token0 → Token1
```

and:

```text
zeroForOne = false
```

means:

```text
Token1 → Token0
```

---

# Swap Formula

For a swap:

```text
reserveIn = input token reserve
reserveOut = output token reserve
```

The fee-adjusted input is:

```text
amountInWithFee = amountIn × 997
```

The output calculation is:

```text
amountOut =
    (amountInWithFee × reserveOut)
    /
    (reserveIn × 1000 + amountInWithFee)
```

This applies the 0.3% trading fee.

---

# Example Swap

Assume:

```text
Token0 reserve = 1000
Token1 reserve = 1000
```

A trader swaps:

```text
10 Token0
```

The fee-adjusted input is:

```text
10 × 997
```

The AMM calculates the corresponding Token1 output using the constant-product pricing formula.

After the swap:

```text
Token0 reserve increases
Token1 reserve decreases
```

The fee remains within the pool.

---

# Constant-Product Invariant

Before a swap:

```text
kBefore = reserve0 × reserve1
```

After the swap:

```text
kAfter = reserve0 × reserve1
```

Because of the trading fee, the implementation tests that:

```text
kAfter >= kBefore
```

for successful swaps.

The fee causes the pool's effective product to increase rather than decrease under the tested swap conditions.

---

# Slippage Protection

The swap function accepts:

```solidity
uint256 amountOutMin
```

The transaction reverts if the calculated output is below the user's minimum acceptable amount.

```text
calculated amountOut < amountOutMin
                ↓
        SlippageExceeded
```

This protects traders against receiving less output than they are willing to accept.

---

# Deadline Protection

Liquidity and swap operations accept a deadline.

For example:

```solidity
if (block.timestamp > deadline) {
    revert TransactionExpired();
}
```

An expired transaction is rejected.

This prevents an old transaction from being executed after the user's intended execution window.

---

# Reentrancy Protection

The AMM uses a custom `nonReentrant` modifier.

```solidity
uint256 private constant NOT_ENTERED = 1;
uint256 private constant ENTERED = 2;

uint256 private reentrancyStatus = NOT_ENTERED;
```

The modifier prevents protected functions from being entered recursively.

It is applied to:

```text
addLiquidity()
removeLiquidity()
swap()
```

This is particularly relevant because these functions interact with external ERC-20 contracts.

---

# Safe ERC-20 Interaction

The AMM uses low-level calls for token transfers:

```solidity
_safeTransfer()
_safeTransferFrom()
```

The implementation accepts ERC-20 tokens that either:

* Return `true`
* Return no data

and reverts when the call fails or explicitly returns `false`.

This is designed to handle common ERC-20 return-value behavior.

---

# Custom Errors

The contract uses custom Solidity errors:

```solidity
error InvalidTokens();
error ZeroAmount();
error InsufficientLiquidity();
error InsufficientLPBalance();
error InsufficientLPAllowance();
error SlippageExceeded();
error TransactionExpired();
error InvalidLiquidityAmounts();
error InsufficientOutputAmount();
error Reentrancy();
error InvalidRecipient();
```

Custom errors provide structured revert information without relying on long revert strings.

---

# LP Token Interface

The AMM implements ERC-20-style LP token accounting:

```solidity
uint256 public totalSupply;

mapping(address => uint256)
    public balanceOf;

mapping(address => mapping(address => uint256))
    public allowance;
```

Supported operations include:

```text
approve()
transfer()
transferFrom()
```

LP tokens represent a liquidity provider's proportional claim on the pool.

---

# Testing Strategy

The project uses Foundry to test:

* Unit behavior
* Revert conditions
* LP token accounting
* Liquidity calculations
* Swap calculations
* Fee calculations
* Reserve accounting
* Slippage protection
* Deadline protection
* Fuzzed inputs
* Stateful invariants

The tests are organized around both individual functions and protocol-level properties.

---

# Test Suite

## Setup Tests

`SetupTest.t.sol`

Tests:

* Token pair initialization
* Initial reserves
* Initial LP supply
* Same-token rejection
* Zero-address rejection

---

# Add Liquidity Tests

`AddLiquidityTest.t.sol`

Tests:

* First liquidity deposit
* Initial LP token calculation
* Minimum liquidity lock
* Second liquidity deposit
* Optimal liquidity ratio
* Zero-amount rejection
* Expired deadline
* Slippage protection
* Insufficient first deposit
* Fuzzed liquidity amounts
* LP total-supply accounting

---

# Remove Liquidity Tests

`RemoveLiquidityTest.t.sol`

Tests:

* Partial liquidity withdrawal
* Full user liquidity withdrawal
* Correct token amounts
* LP token burning
* Reserve updates
* Zero-amount rejection
* Excess LP balance rejection
* Slippage protection
* Expired deadline
* Minimum liquidity remaining

---

# Swap Tests

`SwapTest.t.sol`

Tests:

* Token0 → Token1
* Token1 → Token0
* Swap output calculation
* 0.3% fee
* Constant-product behavior
* `k` growth due to fees
* Slippage protection
* Exact minimum output
* Zero input rejection
* Empty pool rejection
* Insufficient balance
* Expired deadline
* Output reserve limits
* Reserve accounting

---

# Fuzz Testing

The project uses Foundry fuzzing to test protocol behavior against automatically generated inputs.

Examples include:

```text
Fuzzed swap amounts
Fuzzed liquidity deposits
Fuzzed reverse swaps
Fuzzed output bounds
Fuzzed constant-product behavior
Fuzzed LP accounting
```

---

# Fuzzed Swap Properties

For successful swaps, tests verify:

```text
amountOut > 0
```

and:

```text
newReserve0 =
    oldReserve0 + amountIn
```

for Token0 → Token1 swaps.

For the opposite direction:

```text
newReserve1 =
    oldReserve1 + amountIn
```

The output reserve decreases by the calculated output amount.

---

# Constant-Product Fuzz Test

The fuzz suite verifies:

```text
kAfter >= kBefore
```

for successful swaps.

This tests the important AMM property that the fee-adjusted swap should not decrease the product under the implemented accounting model.

---

# Stateful Invariant Testing

The project includes a dedicated Foundry invariant test using a **Handler**.

Files:

```text
Handler.sol
InvariantTest.t.sol
```

The handler exposes randomized protocol actions such as:

```text
add_liquidity()
swap_0_for_1()
swap_1_for_0()
remove_liquidity()
```

Foundry's invariant engine can call these functions in different sequences with fuzzed inputs.

The goal is to test protocol properties across **sequences of state transitions**, rather than only individual transactions.

---

# Invariants

## Token Conservation

The test tracks the combined token balances of the handler and AMM.

For token0:

```text
handler token0
+
AMM token0
=
constant total
```

For token1:

```text
handler token1
+
AMM token1
=
constant total
```

This helps detect unintended token creation or destruction through the tested AMM operations.

---

## Reserve Safety

The invariant suite checks that active pools maintain non-zero reserves.

```text
active liquidity
       ↓
reserve0 > 0
reserve1 > 0
```

---

## Reserve Backing

The tests verify that the AMM's actual token balances are sufficient to cover its recorded reserves.

```text
token0.balanceOf(AMM) >= reserve0
```

and:

```text
token1.balanceOf(AMM) >= reserve1
```

The inequality intentionally allows the possibility of excess token balances caused by direct token transfers to the AMM.

---

## Minimum Liquidity Lock

The invariant suite verifies that:

```text
balanceOf(address(0))
=
MINIMUM_LIQUIDITY
```

This ensures the permanently locked minimum liquidity remains in place.

---

# Handler-Based Testing

The Handler provides a stateful interface for Foundry's invariant engine.

Example actions:

```solidity
function add_liquidity(uint256 amount)

function swap_0_for_1(uint256 amount)

function swap_1_for_0(uint256 amount)

function remove_liquidity(uint256 amount)
```

The invariant engine can generate different action sequences such as:

```text
add liquidity
      ↓
swap
      ↓
swap reverse direction
      ↓
add liquidity
      ↓
remove liquidity
      ↓
swap
      ↓
...
```

This is more representative of protocol-level testing than isolated unit tests.

---

# Security Considerations

This project was designed with several security considerations in mind.

### Reentrancy

Liquidity and swap functions use a reentrancy guard because they interact with external token contracts.

### Slippage

Users can specify minimum acceptable amounts.

### Deadlines

Operations reject expired transactions.

### Reserve Accounting

The contract explicitly tracks reserves and updates them after state-changing operations.

### Arithmetic

Solidity `0.8.x` provides checked arithmetic for overflow and underflow conditions.

### Token Transfer Failures

Low-level token interactions verify call success and ERC-20 return values.

### Minimum Liquidity

A minimum amount of LP liquidity is permanently locked.

---

# Important Limitations

This is an educational AMM implementation, not a production DEX.

It does not implement every feature or security property expected from a production AMM.

Examples of additional production considerations include:

* Oracle manipulation
* MEV
* Sandwich attacks
* Flash-loan interactions
* TWAP/oracle design
* Fee-on-transfer tokens
* Rebasing tokens
* ERC-777 hooks
* Non-standard ERC-20 behavior
* Protocol-wide economic attacks
* Precision and rounding analysis
* Formal verification
* Comprehensive invariant coverage
* Static analysis
* External security review
* Production-grade access/control architecture
* Comprehensive integration testing

---

# MockERC20

The repository includes:

```text
MockERC20.sol
```

for testing.

The mock token intentionally provides unrestricted minting:

```solidity
function mint(
    address to,
    uint256 amount
) external
```

This is useful for creating arbitrary test states.

> The unrestricted mint function exists only for testing and must not be treated as production token logic.

---

# Why I Built This

I built SimpleAMM to understand how decentralized exchanges implement liquidity pools and constant-product pricing at the Solidity level.

The project allowed me to practice:

* AMM mathematics
* `x * y = k`
* Swap fee calculations
* Liquidity-provider accounting
* LP token mechanics
* Reserve management
* Slippage protection
* Deadline protection
* ERC-20 interaction
* Reentrancy protection
* Foundry fuzz testing
* Stateful invariant testing

---

# Key Engineering Concepts

### AMM Mathematics

```text
x * y = k
```

### Swap Fee

```text
0.3%
```

### Fee-adjusted input

```text
amountIn × 997 / 1000
```

### First LP deposit

```text
sqrt(amount0 × amount1)
-
MINIMUM_LIQUIDITY
```

### LP withdrawal

```text
liquidity / totalSupply
```

determines the provider's proportional share of reserves.

---

# Project Structure

```text
simple-amm-solidity/
│
├── src/
│   ├── IERC20.sol
│   ├── MockERC20.sol
│   └── SimpleAMM.sol
│
├── test/
│   ├── SetupTest.t.sol
│   ├── AddLiquidityTest.t.sol
│   ├── RemoveLiquidityTest.t.sol
│   ├── SwapTest.t.sol
│   ├── FuzzBoundsTest.t.sol
│   ├── Handler.sol
│   └── InvariantTest.t.sol
│
├── script/
│
├── lib/
│
├── foundry.toml
├── .gitignore
└── README.md
```

---

# Getting Started

## Prerequisites

Install:

* Git
* Foundry

---

## Clone

```bash
git clone https://github.com/Pravinru17/simple-amm-solidity.git
```

Enter the repository:

```bash
cd simple-amm-solidity
```

---

# Install Dependencies

If dependencies are not already installed:

```bash
forge install
```

---

# Build

Compile the contracts:

```bash
forge build
```

---

# Format

Format the Solidity code:

```bash
forge fmt
```

Check formatting:

```bash
forge fmt --check
```

---

# Run Tests

Run the complete test suite:

```bash
forge test
```

Run with detailed output:

```bash
forge test -vv
```

Run with maximum verbosity:

```bash
forge test -vvvv
```

---

# Run Fuzz Tests

Run the fuzz tests:

```bash
forge test --match-test Fuzz
```

---

# Run Invariant Tests

Run the invariant test contract:

```bash
forge test --match-contract InvariantTest
```

For detailed invariant execution:

```bash
forge test --match-contract InvariantTest -vv
```

---

# Run Coverage

```bash
forge coverage
```

---

# Gas Snapshot

Generate a gas snapshot:

```bash
forge snapshot
```

---

# Local Development

Start Anvil:

```bash
anvil
```

Anvil provides a local Ethereum-compatible blockchain for deployment and interaction testing.

---

# Security Analysis

The contracts can also be analyzed with static-analysis tools such as:

```bash
slither .
```

Additional tools that can be used for security research include:

* Slither
* Aderyn
* Foundry
* Echidna
* Solodit
* Code4rena
* Immunefi

---

# Testing Philosophy

The project uses multiple layers of testing:

```text
Unit Tests
    ↓
Fuzz Tests
    ↓
Property Tests
    ↓
Stateful Invariant Tests
    ↓
Security Analysis
```

Each layer targets a different class of failure.

---

# What This Project Demonstrates

This project demonstrates practical experience with:

* Solidity `^0.8.20`
* DeFi mechanics
* AMM design
* Constant-product pricing
* Liquidity pools
* LP tokens
* ERC-20 interactions
* Safe token transfers
* Swap fee calculations
* Reserve accounting
* Slippage protection
* Transaction deadlines
* Reentrancy protection
* Custom errors
* Foundry
* Forge
* Fuzz testing
* Stateful invariant testing
* Handler-based testing
* Security-oriented development

---

# Educational Disclaimer

This AMM is an educational implementation.

It has not been independently audited and should not be used to manage real funds.

The implementation is intended to demonstrate understanding of:

```text
AMM mechanics
+
Solidity
+
DeFi accounting
+
Foundry testing
+
Smart-contract security
```

Production AMMs require substantially more testing, economic analysis, formal reasoning, integration testing, and professional security review.

---

# Author

**Pravin R**

Junior Solidity / Blockchain Developer

GitHub: https://github.com/Pravinru17

---

# License

MIT
