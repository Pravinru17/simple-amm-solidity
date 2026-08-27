// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleAMM.sol";
import "../src/MockERC20.sol";

contract SetupTest is Test {
    SimpleAMM amm;
    MockERC20 token0;
    MockERC20 token1;

    address lp = address(0x1);

    function setUp() public {
        token0 = new MockERC20("Token A", "TKA");
        token1 = new MockERC20("Token B", "TKB");

        // Mint test tokens to this test contract.
        token0.mint(address(this), 1_000_000e18);
        token1.mint(address(this), 1_000_000e18);

        amm = new SimpleAMM(
            address(token0),
            address(token1)
        );
    }

    function test_ConstructorSetsTokens() public {
        assertEq(
            amm.token0(),
            address(token0)
        );

        assertEq(
            amm.token1(),
            address(token1)
        );
    }

    function test_InitialReservesAreZero() public {
        assertEq(
            amm.reserve0(),
            0
        );

        assertEq(
            amm.reserve1(),
            0
        );
    }

    function test_InitialSupplyIsZero() public {
        assertEq(
            amm.totalSupply(),
            0
        );
    }

    function test_Constructor_RevertIfSameToken() public {
        vm.expectRevert(
            SimpleAMM.InvalidTokens.selector
        );

        new SimpleAMM(
            address(token0),
            address(token0)
        );
    }

    function test_Constructor_RevertIfZeroAddress() public {
        vm.expectRevert(
            SimpleAMM.InvalidTokens.selector
        );

        new SimpleAMM(
            address(0),
            address(token1)
        );
    }
}