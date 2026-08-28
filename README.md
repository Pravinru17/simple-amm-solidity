# MyToken — ERC-20 Solidity

A security-focused educational implementation of an ERC-20-style token written in **Solidity 0.8.20** and tested with **Foundry**.

The project implements token transfers, approvals, delegated transfers, token burning, custom Solidity errors, event emission, fuzz testing, and invariant-style accounting tests.

## Features

* ERC-20-style token implementation
* `transfer()`
* `approve()`
* `transferFrom()`
* `balanceOf()`
* `allowance()`
* `burn()`
* 18 decimal places
* Initial token supply minted to the deployer
* Custom Solidity errors
* `Transfer` event
* `Approval` event
* Zero-address validation
* Zero-amount validation
* Insufficient-balance protection
* Allowance validation
* Burn accounting
* Total-supply accounting
* Fuzz testing
* Invariant-style testing
* Foundry-based development and testing

## Security / Engineering Focus

This project focuses on understanding and testing core ERC-20 token mechanics.

Key areas include:

* State accounting
* Balance management
* Allowance management
* `msg.sender` authorization
* Custom error handling
* Event correctness
* Boundary-condition testing
* Property-based fuzz testing
* Supply conservation
* Burn accounting

## Contract Architecture

The token maintains balances and allowances using Solidity mappings:

```solidity
mapping(address => uint256) private _balances;
mapping(address => mapping(address => uint256)) private _allowances;
```

The contract also tracks:

```solidity
uint256 public totalSupply;
```

### Token Metadata

The constructor initializes:

```solidity
name
symbol
decimals
totalSupply
```

The initial supply is minted directly to the deployer.

## Custom Errors

Instead of string-based `require()` messages, the contract uses custom Solidity errors.

Examples:

```solidity
error ERC20__ZeroAddress();

error ERC20__ZeroAmount();

error ERC20__InsufficientBalance(
    uint256 available,
    uint256 required
);

error ERC20__ExceedsAllowance(
    uint256 allowance,
    uint256 required
);
```

This provides structured revert information and avoids storing long revert strings.

## Token Operations

### Transfer

Users can transfer tokens directly:

```text
Alice
  |
  | transfer(Bob, amount)
  v
Bob receives tokens
```

The contract validates:

* Recipient is not the zero address
* Amount is greater than zero
* Sender has sufficient balance

### Approve

Token holders can approve another address to spend tokens:

```text
Alice
  |
  | approve(Bob, amount)
  v
Bob receives allowance
```

### TransferFrom

An approved spender can transfer tokens on behalf of the token owner:

```text
Alice
  |
  | approve(Bob, amount)
  v
Bob
  |
  | transferFrom(Alice, Carol, amount)
  v
Carol receives tokens
```

After the transfer, the allowance is reduced by the amount spent.

### Burn

A token holder can permanently destroy their own tokens.

Burning decreases:

```text
totalSupply
```

and:

```text
account balance
```

by the same amount.

## Testing

The project uses **Foundry / Forge** for automated testing.

### Unit Tests

The test suite verifies specific scenarios including:

* Constructor state
* Initial supply validation
* Transfer event emission

### Fuzz Testing

Foundry fuzz tests are used to test the contract with automatically generated inputs.

Fuzz tests cover:

* Transfers with arbitrary valid amounts
* Transfers to arbitrary non-zero addresses
* Transfers exceeding available balance
* Transfers to the zero address
* Zero-value transfers
* Arbitrary approval amounts
* Approval to the zero address
* Valid `transferFrom()` operations
* `transferFrom()` exceeding allowance
* `transferFrom()` to the zero address
* Token burning
* Burning more than the available balance
* Zero-value burning

### Invariant-Style Tests

The test suite also verifies important token accounting properties.

#### Transfers preserve total supply

A transfer moves tokens between accounts but must not change total supply.

```text
totalSupply_before == totalSupply_after
```

#### Balance accounting

After a series of transfers, the tracked balances must equal total supply for the accounts covered by the test.

```text
sum of tracked balances == totalSupply
```

#### Burning reduces supply correctly

If `X` tokens are burned:

```text
totalSupply_after = totalSupply_before - X
```

and:

```text
balance_after = balance_before - X
```

## Project Structure

```text
erc20-foundry/
├── src/
│   └── MyToken.sol
│
├── test/
│   └── MyToken.t.sol
│
├── script/
├── lib/
├── foundry.toml
├── .gitignore
└── README.md
```

## Getting Started

Clone the repository:

```bash
git clone https://github.com/Pravinru17/erc20-foundry-.git
cd erc20-foundry-
```

Install dependencies if required:

```bash
forge install
```

## Build

Compile the contracts:

```bash
forge build
```

## Test

Run the complete test suite:

```bash
forge test
```

Run tests with traces:

```bash
forge test -vv
```

Run with maximum verbosity:

```bash
forge test -vvvv
```

## Format

Format Solidity files:

```bash
forge fmt
```

## Gas Snapshots

Generate gas snapshots:

```bash
forge snapshot
```

## Local Development

Start a local Ethereum node using Anvil:

```bash
anvil
```

## Deployment

A deployment script can be executed using:

```bash
forge script script/Counter.s.sol:CounterScript \
  --rpc-url <your_rpc_url> \
  --private-key <your_private_key>
```

Replace the example script with the appropriate deployment script for `MyToken`.

**Never commit private keys or other secrets to the repository.**

## Limitations

This project is an educational implementation and should not be treated as production-ready without further review.

It intentionally implements ERC-20-style functionality directly instead of inheriting from OpenZeppelin's ERC-20 implementation.

For production use, additional considerations would include:

* Full ERC-20 compatibility testing
* Integration testing
* Comprehensive invariant testing
* Static analysis
* Formal verification where appropriate
* External security review
* Wallet and protocol compatibility testing

## Learning Objectives

This project demonstrates practical experience with:

* Solidity `^0.8.20`
* ERC-20 token mechanics
* Solidity mappings
* Allowances
* Events
* Custom errors
* Revert handling
* State accounting
* Foundry
* Forge
* Fuzz testing
* Invariant-style testing
* Boundary-condition testing

## Author

**Pravin R**

Blockchain / Solidity Developer

GitHub: [Pravinru17](https://github.com/Pravinru17)

## License

MIT
