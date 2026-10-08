# SimpleAMM — Constant-Product AMM in Solidity

A security-focused implementation of a Uniswap V2-inspired Automated Market Maker (AMM) built with Solidity and Foundry.

SimpleAMM implements constant-product pricing, liquidity provision, LP token accounting, swaps, a 0.3% trading fee, slippage protection, transaction deadlines, minimum liquidity locking, reentrancy protection, fuzz testing, and stateful invariant testing.

> ⚠️ **Educational Project:** This implementation is intended for Solidity, DeFi, and smart-contract security learning. It has not been independently audited and should not be used with real funds.

---

## Highlights

- Constant-product AMM: `x × y = k`
- Two-token liquidity pool
- Liquidity provision and withdrawal
- LP token minting and burning
- 0.3% swap fee
- Token0 → Token1 swaps
- Token1 → Token0 swaps
- Slippage protection
- Transaction deadline protection
- Minimum liquidity locking
- Reentrancy protection
- Custom Solidity errors
- Safe ERC-20 interactions
- Foundry unit testing
- Foundry fuzz testing
- Stateful invariant testing
- Handler-based protocol testing
- Reserve accounting validation
- Token conservation invariants

---

# Test Results

SimpleAMM is tested using Foundry unit tests, fuzz tests, and stateful invariant tests.

## Full Test Suite

```text
6 test suites
46 tests passed
0 failed
0 skipped

Test Suite Breakdown
Test Suite	Tests	Result
SetupTest.t.sol	5	✅ 5 passed
FuzzBoundsTest.t.sol	5	✅ 5 passed
RemoveLiquidityTest.t.sol	8	✅ 8 passed
AddLiquidityTest.t.sol	10	✅ 10 passed
SwapTest.t.sol	12	✅ 12 passed
InvariantTest.t.sol	6	✅ 6 passed
Total	46	✅ 46 passed


Fuzz Testing
Foundry fuzz testing is used to test AMM calculations against automatically generated inputs.
Test	Runs	Result
testFuzz_AddLiquidity(uint256)	256	✅ PASS
testFuzz_KNeverDecreases(uint256)	257	✅ PASS
testFuzz_Swap(uint256)	257	✅ PASS
testFuzz_SwapOutputNeverExceedsReserve(uint256)	257	✅ PASS
testFuzz_SwapReverse(uint256)	257	✅ PASS


The fuzz suite tests:
- Liquidity bounds
- First-deposit calculations
- LP accounting
- Swap calculations
- Swap output limits
- Reverse-direction swaps
- Constant-product behavior
All fuzz tests passed.
Stateful Invariant Testing
SimpleAMM uses a Foundry Handler to generate sequences of protocol operations and verify protocol-level properties.
Each invariant was executed with:
Runs:      100
Calls:     10,000
Reverts:   0

Invariants Tested
- invariant_MinimumLiquidityLocked()
- invariant_ReservesBackedByBalances()
- invariant_ReservesMatchTokenBalances()
- invariant_ReservesNonZero()
- invariant_Token0Conservation()
- invariant_Token1Conservation()
All six invariant tests passed.
Handler Actions
add_liquidity
remove_liquidity
setK
swap_0_for_1
swap_1_for_0

Example state transitions:
Add Liquidity
      ↓
Swap
      ↓
Reverse Swap
      ↓
Add Liquidity
      ↓
Remove Liquidity
      ↓
Swap
      ↓
...

This provides protocol-level testing beyond isolated unit tests.
Overview
SimpleAMM is a two-token automated market maker based on the constant-product model:
x × y = k

Where:
x = Token0 reserve
y = Token1 reserve
k = constant-product invariant

Liquidity providers deposit both tokens into the pool and receive LP tokens representing their proportional share of the pool.
Traders can swap:
Token0 → Token1

or:
Token1 → Token0

AMM Architecture
                     SimpleAMM
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
       Token0         Reserves        Token1
          │              │              │
          └──────────────┼──────────────┘
                         │
                 LP Token Accounting
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
       Add Liquidity         Remove Liquidity
              │
              ▼
            Swap

The AMM explicitly tracks:
uint256 public reserve0;
uint256 public reserve1;

These reserves are updated after liquidity operations and swaps.
Core AMM Formula
The pool follows:
reserve0 × reserve1 = k

For a swap, the fee-adjusted input is:
amountInWithFee = amountIn × 997

The output amount is calculated as:
amountOut =
    (amountInWithFee × reserveOut)
    /
    (reserveIn × 1000 + amountInWithFee)

The implementation uses:
uint256 public constant FEE_NUMERATOR = 997;
uint256 public constant FEE_DENOMINATOR = 1000;

This represents a 0.3% trading fee.
The fee remains inside the pool and contributes to the growth of k.
Liquidity Provision
Liquidity providers use:
addLiquidity()

The function accepts:
function addLiquidity(
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min,
    uint256 deadline
)

The parameters provide:
- Desired Token0 amount
- Desired Token1 amount
- Minimum acceptable Token0 amount
- Minimum acceptable Token1 amount
- Transaction deadline
First Liquidity Deposit
For the first liquidity provider:
liquidity = sqrt(amount0 × amount1)

The implementation uses:
uint256 public constant MINIMUM_LIQUIDITY = 1000;

Therefore:
LP minted =
sqrt(amount0 × amount1)
- MINIMUM_LIQUIDITY

The minimum liquidity is permanently locked to:
address(0)

This prevents the pool from becoming completely empty of LP liquidity.
Subsequent Liquidity Deposits
For an existing pool, liquidity is calculated using the current reserve ratio.
For example:
Current Pool:

1000 Token0
1000 Token1

If a user wants to deposit:
2000 Token0
1000 Token1

the AMM only uses the amount required to maintain the pool ratio.
This prevents unnecessary token deposits.
LP Token Accounting
The AMM implements ERC-20-style LP token accounting:
uint256 public totalSupply;

mapping(address => uint256)
    public balanceOf;

mapping(address => mapping(address => uint256))
    public allowance;

Supported operations include:
approve()
transfer()
transferFrom()

When liquidity is added:
Tokens deposited
       ↓
LP tokens minted

When liquidity is removed:
LP tokens burned
       ↓
Underlying tokens returned

LP tokens represent the liquidity provider's proportional claim on the pool.
Removing Liquidity
Liquidity providers use:
removeLiquidity()

The function accepts:
function removeLiquidity(
    uint256 liquidity,
    uint256 amount0Min,
    uint256 amount1Min,
    uint256 deadline
)

The user's proportional share is calculated using:
amount0 =
liquidity × reserve0
/
totalSupply

and:
amount1 =
liquidity × reserve1
/
totalSupply

The corresponding LP tokens are then burned.
Swaps
SimpleAMM supports both directions:
Token0 → Token1

and:
Token1 → Token0

The swap function is:
function swap(
    uint256 amountIn,
    bool zeroForOne,
    uint256 amountOutMin,
    uint256 deadline
)

Where:
zeroForOne = true

means:
Token0 → Token1

and:
zeroForOne = false

means:
Token1 → Token0

0.3% Swap Fee
The AMM charges:
0.3%

The fee-adjusted input is:
amountIn × 997 / 1000

The test suite explicitly verifies:
test_Swap_ChargesPointThreePercentFee()
test_Swap_KIncreasesDueToFee()

The fee remains inside the pool.
Constant-Product Behavior
Before a swap:
kBefore = reserve0 × reserve1

After a successful swap:
kAfter = reserve0 × reserve1

The fuzz suite verifies:
kAfter >= kBefore

under the implemented fee and accounting model.
Slippage Protection
Users provide a minimum acceptable output:
uint256 amountOutMin

If:
calculated amountOut < amountOutMin

the transaction reverts.
This protects users from receiving less than the amount they are willing to accept.
Tests include:
test_Swap_RevertIfSlippageExceeded()
test_Swap_PassesIfExactSlippage()
test_AddLiquidity_SlippageExceeded_Reverts()
test_RemoveLiquidity_SlippageProtection()

Deadline Protection
Liquidity and swap operations support transaction deadlines.
Conceptually:
if (block.timestamp > deadline) {
    revert TransactionExpired();
}

Expired transactions are rejected.
This prevents stale transactions from executing outside the user's intended execution window.
Tests include:
test_Swap_ExpiredDeadline_Reverts()
test_AddLiquidity_ExpiredDeadline_Reverts()
test_RemoveLiquidity_ExpiredDeadline()

Reentrancy Protection
The AMM implements a custom reentrancy guard:
uint256 private constant NOT_ENTERED = 1;
uint256 private constant ENTERED = 2;

uint256 private reentrancyStatus = NOT_ENTERED;

The guard prevents recursive entry into protected functions.
It is applied to:
addLiquidity()
removeLiquidity()
swap()

This is important because these functions interact with external ERC-20 contracts.
Safe ERC-20 Interaction
The AMM uses internal safe-transfer functions:
_safeTransfer()
_safeTransferFrom()

The implementation checks:
- Low-level call success
- Explicit false return values
- No-return-data ERC-20 behavior
This is designed to handle common ERC-20 return-value behavior.
Custom Errors
The contract uses custom Solidity errors:
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

Custom errors provide structured revert information without relying on long revert strings.
Testing Strategy
The project uses multiple layers of testing:
Unit Tests
     ↓
Fuzz Tests
     ↓
Property Tests
     ↓
Stateful Invariant Tests
     ↓
Security Analysis

Each layer targets a different class of failure.
Test Suite Details
SetupTest.t.sol
Tests:
- Token pair initialization
- Initial reserves
- Initial LP supply
- Same-token rejection
- Zero-address rejection
Result:
5 passed
0 failed

AddLiquidityTest.t.sol
Tests:
- First liquidity deposit
- Initial LP calculation
- Minimum liquidity lock
- Second liquidity deposit
- Optimal liquidity ratio
- Zero-amount rejection
- Expired deadline
- Slippage protection
- Insufficient first deposit
- Fuzzed liquidity amounts
- LP total-supply accounting
Result:
10 passed
0 failed

RemoveLiquidityTest.t.sol
Tests:
- Partial liquidity withdrawal
- Full user liquidity withdrawal
- Correct token amounts
- LP token burning
- Reserve updates
- Zero-amount rejection
- Excess LP balance rejection
- Slippage protection
- Expired deadline
Result:
8 passed
0 failed

SwapTest.t.sol
Tests:
- Token0 → Token1
- Token1 → Token0
- Swap output calculation
- 0.3% fee
- Constant-product behavior
- k growth due to fees
- Slippage protection
- Exact minimum output
- Zero input rejection
- Empty pool rejection
- Insufficient balance
- Expired deadline
- Output reserve limits
- Reserve accounting
Result:
12 passed
0 failed

FuzzBoundsTest.t.sol
Tests:
- Fuzzed liquidity amounts
- Fuzzed constant-product behavior
- Fuzzed swaps
- Fuzzed swap output bounds
- Fuzzed reverse swaps
Result:
5 passed
0 failed

InvariantTest.t.sol
Tests:
- Minimum liquidity remains locked
- Reserves are backed by token balances
- Reserves match token balances
- Reserves remain non-zero
- Token0 conservation
- Token1 conservation
Result:
6 passed
0 failed

Coverage
The supplied forge coverage output reports:
File	Lines	Statements	Branches	Functions
src/MockERC20.sol	92.86% (26/28)	91.30% (21/23)	33.33% (1/3)	100.00% (5/5)
src/SimpleAMM.sol	83.15% (153/184)	84.48% (147/174)	65.79% (25/38)	80.00% (12/15)
test/Handler.sol	85.19% (46/54)	84.62% (44/52)	55.56% (5/9)	90.00% (9/10)


Note: The provided forge coverage output did not include the final Total row, so no overall coverage percentage is claimed.

Project Structure
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

Tech Stack
Technology	Usage
Solidity ^0.8.20	Smart contracts
Foundry / Forge	Testing and development
Anvil	Local Ethereum blockchain
Git	Version control
GitHub	Source control


Getting Started
Prerequisites
Install:
- Git
- Foundry
Clone
git clone https://github.com/Pravinru17/simple-amm-solidity.git

cd simple-amm-solidity

Install Dependencies
forge install

Build
forge build

Format
forge fmt

Check formatting:
forge fmt --check

Run Tests
Run the complete test suite:
forge test

Detailed output:
forge test -vv

Maximum verbosity:
forge test -vvvv

Run Fuzz Tests
forge test --match-test Fuzz

Run Invariant Tests
forge test --match-contract InvariantTest

Detailed invariant execution:
forge test --match-contract InvariantTest -vv

Coverage
forge coverage

Gas Snapshot
forge snapshot

Local Development
Start Anvil:
anvil

Anvil provides a local Ethereum-compatible blockchain for deployment and interaction testing.
Security Analysis
Static analysis can be performed using:
slither .

Other useful security research tools include:
- Slither
- Aderyn
- Foundry
- Echidna
- Solodit
- Code4rena
- Immunefi
Key Engineering Concepts
AMM Mathematics
x × y = k

Swap Fee
0.3%

Fee-Adjusted Input
amountIn × 997 / 1000

First LP Deposit
sqrt(amount0 × amount1)
-
MINIMUM_LIQUIDITY

LP Withdrawal
liquidity / totalSupply

determines the provider's proportional share of pool reserves.
Security Considerations
Reentrancy
Liquidity and swap functions use a reentrancy guard because they interact with external token contracts.
Slippage
Users can specify minimum acceptable amounts.
Deadlines
Operations reject expired transactions.
Reserve Accounting
The contract explicitly tracks reserves and updates them after state-changing operations.
Arithmetic
Solidity 0.8.x provides checked arithmetic for overflow and underflow conditions.
Token Transfer Failures
Low-level token interactions verify call success and ERC-20 return values.
Minimum Liquidity
A minimum amount of LP liquidity is permanently locked.
MockERC20
The repository includes:
MockERC20.sol

for testing.
The mock token provides unrestricted minting so that tests can create arbitrary token balances and protocol states.
This functionality exists only for testing and must not be treated as production token logic.
Limitations
This is an educational AMM implementation, not a production DEX.
Production deployment would require additional testing and security analysis, including:
- Oracle manipulation
- MEV
- Sandwich attacks
- Flash-loan interactions
- TWAP/oracle design
- Fee-on-transfer tokens
- Rebasing tokens
- ERC-777 hooks
- Non-standard ERC-20 behavior
- Protocol-wide economic attacks
- Precision and rounding analysis
- Formal verification
- Comprehensive invariant coverage
- Static analysis
- External security review
- Production-grade access/control architecture
- Comprehensive integration testing
What This Project Demonstrates
This project demonstrates practical experience with:
- Solidity ^0.8.20
- DeFi mechanics
- AMM design
- Constant-product pricing
- Liquidity pools
- LP tokens
- ERC-20 interactions
- Safe token transfers
- Swap fee calculations
- Reserve accounting
- Slippage protection
- Transaction deadlines
- Reentrancy protection
- Custom errors
- Foundry / Forge
- Fuzz testing
- Stateful invariant testing
- Handler-based testing
- Security-oriented development
Why I Built This
I built SimpleAMM to understand how decentralized exchanges implement liquidity pools and constant-product pricing at the Solidity level.
The project allowed me to practice:
- AMM mathematics
- Swap fee calculations
- Liquidity-provider accounting
- LP token mechanics
- Reserve management
- Slippage protection
- Deadline protection
- ERC-20 interaction
- Reentrancy protection
- Foundry fuzz testing
- Stateful invariant testing
The main focus was not only implementing the AMM, but also testing protocol-level properties across many possible state transitions.
Testing Philosophy
The project follows a layered security-oriented testing approach:
Unit Tests
    ↓
Fuzz Testing
    ↓
Property Testing
    ↓
Stateful Invariant Testing
    ↓
Static Analysis
    ↓
Security Research

The goal is to test both:
1. Individual contract behavior
2. Protocol-level state consistency
Security Disclaimer
This project is for educational and research purposes.
It has not been independently audited and should not be used to manage real funds.
The implementation demonstrates understanding of:
AMM Mechanics
      +
Solidity
      +
DeFi Accounting
      +
Foundry Testing
      +
Smart-Contract Security

Production AMMs require substantially more testing, economic analysis, formal reasoning, integration testing, and professional security review.
Author
Pravin R.
Junior Solidity / Blockchain Developer
Focus
- Solidity
- Foundry
- DeFi
- Smart Contract Security
- Smart Contract Testing
GitHub:
https://github.com/Pravinru17
License
MIT
```
