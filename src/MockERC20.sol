// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";

/// @title MockERC20
/// @notice Simple ERC20 token used for AMM testing.
/// @dev Unrestricted minting is intentional for testing. DO NOT use in production.
contract MockERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(
        string memory _name,
        string memory _symbol
    ) {
        name = _name;
        symbol = _symbol;
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) external override returns (bool) {
        if (balanceOf[msg.sender] < amount) {
            revert InsufficientBalance();
        }

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        if (allowance[from][msg.sender] < amount) {
            revert InsufficientAllowance();
        }

        if (balanceOf[from] < amount) {
            revert InsufficientBalance();
        }

        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);

        return true;
    }

    /// @notice Unrestricted mint function for testing.
    function mint(
        address to,
        uint256 amount
    ) external {
        totalSupply += amount;
        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    error InsufficientBalance();
    error InsufficientAllowance();
}