// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleAMM.sol";
import "../src/MockERC20.sol";
import "./Handler.sol";

/// @title InvariantTest
/// @notice Exercises arbitrary sequences of AMM operations
/// and verifies protocol invariants that remain valid
/// across swaps, deposits, and withdrawals.
contract InvariantTest is Test {
    SimpleAMM amm;
    MockERC20 token0;
    MockERC20 token1;
    Handler handler;

    uint256 startingToken0;
    uint256 startingToken1;

    function setUp() public {
        token0 = new MockERC20(
            "Token A",
            "TKA"
        );

        token1 = new MockERC20(
            "Token B",
            "TKB"
        );

        amm = new SimpleAMM(
            address(token0),
            address(token1)
        );

        handler = new Handler(
            address(amm),
            address(token0),
            address(token1)
        );

        // Seed the pool.
        token0.mint(
            address(handler),
            1000e18
        );

        token1.mint(
            address(handler),
            1000e18
        );

        handler.add_liquidity(
            1000e18
        );

        // Record initial token totals.
        startingToken0 =
            handler.totalToken0();

        startingToken1 =
            handler.totalToken1();

        // Tell Foundry to fuzz the Handler.
        targetContract(
            address(handler)
        );
    }

    // =============================================================
    //                 TOKEN CONSERVATION
    // =============================================================

    function invariant_Token0Conservation()
        public
        view
    {
        assertEq(
            handler.totalToken0(),
            startingToken0,
            "Token0 was created or destroyed"
        );
    }

    function invariant_Token1Conservation()
        public
        view
    {
        assertEq(
            handler.totalToken1(),
            startingToken1,
            "Token1 was created or destroyed"
        );
    }

    // =============================================================
    //                     RESERVE INVARIANTS
    // =============================================================

    function invariant_ReservesNonZero()
        public
        view
    {
        if (
            amm.totalSupply() >
            amm.MINIMUM_LIQUIDITY()
        ) {
            assertGt(
                amm.reserve0(),
                0,
                "Reserve0 is zero with active liquidity"
            );

            assertGt(
                amm.reserve1(),
                0,
                "Reserve1 is zero with active liquidity"
            );
        }
    }

    function invariant_ReservesBackedByBalances()
        public
        view
    {
        assertGe(
            token0.balanceOf(address(amm)),
            amm.reserve0(),
            "Reserve0 is not backed by token balance"
        );

        assertGe(
            token1.balanceOf(address(amm)),
            amm.reserve1(),
            "Reserve1 is not backed by token balance"
        );
    }

    // =============================================================
    //                    SUPPLY INVARIANT
    // =============================================================

    function invariant_MinimumLiquidityLocked()
        public
        view
    {
        assertEq(
            amm.balanceOf(address(0)),
            amm.MINIMUM_LIQUIDITY(),
            "Minimum liquidity is not locked"
        );
    }

    // =============================================================
    //                  RESERVE SANITY CHECKS
    // =============================================================

    function invariant_ReservesMatchTokenBalances()
        public
        view
    {
        uint256 balance0 =
            token0.balanceOf(address(amm));

        uint256 balance1 =
            token1.balanceOf(address(amm));

        assertGe(
            balance0,
            amm.reserve0()
        );

        assertGe(
            balance1,
            amm.reserve1()
        );
    }
}