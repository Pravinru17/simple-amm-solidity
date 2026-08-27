// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleAMM.sol";
import "../src/MockERC20.sol";

contract SwapTest is Test {
    SimpleAMM amm;
    MockERC20 token0;
    MockERC20 token1;

    address lp = address(0x1);
    address trader = address(0x2);

    function setUp() public {
        token0 = new MockERC20("Token A", "TKA");
        token1 = new MockERC20("Token B", "TKB");

        amm = new SimpleAMM(
            address(token0),
            address(token1)
        );

        token0.mint(lp, 10_000e18);
        token1.mint(lp, 10_000e18);

        token0.mint(trader, 10_000e18);
        token1.mint(trader, 10_000e18);

        vm.startPrank(lp);

        token0.approve(
            address(amm),
            type(uint256).max
        );

        token1.approve(
            address(amm),
            type(uint256).max
        );

        vm.stopPrank();

        vm.startPrank(trader);

        token0.approve(
            address(amm),
            type(uint256).max
        );

        token1.approve(
            address(amm),
            type(uint256).max
        );

        vm.stopPrank();

        vm.prank(lp);

        amm.addLiquidity(
            1000e18,
            1000e18,
            0,
            0,
            block.timestamp + 100
        );
    }

    // =============================================================
    //                         BASIC SWAPS
    // =============================================================

    function test_Swap_Token0ForToken1() public {
        uint256 amountIn = 10e18;

        uint256 amountInWithFee =
            amountIn * 997;

        uint256 expectedOut =
            (
                amountInWithFee *
                1000e18
            ) /
            (
                1000e18 * 1000 +
                amountInWithFee
            );

        uint256 traderToken1Before =
            token1.balanceOf(trader);

        vm.prank(trader);

        uint256 amountOut = amm.swap(
            amountIn,
            true,
            0,
            block.timestamp + 100
        );

        assertEq(
            amountOut,
            expectedOut
        );

        assertEq(
            token1.balanceOf(trader),
            traderToken1Before + expectedOut
        );

        assertEq(
            amm.reserve0(),
            1000e18 + amountIn
        );

        assertEq(
            amm.reserve1(),
            1000e18 - expectedOut
        );
    }

    function test_Swap_Token1ForToken0() public {
        uint256 amountIn = 10e18;

        uint256 amountInWithFee =
            amountIn * 997;

        uint256 expectedOut =
            (
                amountInWithFee *
                1000e18
            ) /
            (
                1000e18 * 1000 +
                amountInWithFee
            );

        uint256 traderToken0Before =
            token0.balanceOf(trader);

        vm.prank(trader);

        uint256 amountOut = amm.swap(
            amountIn,
            false,
            0,
            block.timestamp + 100
        );

        assertEq(
            amountOut,
            expectedOut
        );

        assertEq(
            token0.balanceOf(trader),
            traderToken0Before + expectedOut
        );

        assertEq(
            amm.reserve1(),
            1000e18 + amountIn
        );

        assertEq(
            amm.reserve0(),
            1000e18 - expectedOut
        );
    }

    // =============================================================
    //                         FEE TEST
    // =============================================================

    function test_Swap_ChargesPointThreePercentFee() public {
        uint256 amountIn = 10e18;

        uint256 amountInWithFee =
            amountIn * 997;

        uint256 expectedOut =
            (
                amountInWithFee *
                1000e18
            ) /
            (
                1000e18 * 1000 +
                amountInWithFee
            );

        vm.prank(trader);

        uint256 amountOut = amm.swap(
            amountIn,
            true,
            0,
            block.timestamp + 100
        );

        assertEq(
            amountOut,
            expectedOut
        );
    }

    function test_Swap_KIncreasesDueToFee() public {
        uint256 kBefore =
            amm.reserve0() *
            amm.reserve1();

        vm.prank(trader);

        amm.swap(
            10e18,
            true,
            0,
            block.timestamp + 100
        );

        uint256 kAfter =
            amm.reserve0() *
            amm.reserve1();

        assertGt(
            kAfter,
            kBefore,
            "K should increase because of the fee"
        );
    }

    // =============================================================
    //                     SLIPPAGE PROTECTION
    // =============================================================

    function test_Swap_RevertIfSlippageExceeded() public {
        uint256 amountIn = 10e18;

        uint256 amountInWithFee =
            amountIn * 997;

        uint256 expectedOut =
            (
                amountInWithFee *
                1000e18
            ) /
            (
                1000e18 * 1000 +
                amountInWithFee
            );

        uint256 greedyMinOut =
            expectedOut + 1e18;

        vm.prank(trader);

        vm.expectRevert(
            SimpleAMM.SlippageExceeded.selector
        );

        amm.swap(
            amountIn,
            true,
            greedyMinOut,
            block.timestamp + 100
        );
    }

    function test_Swap_PassesIfExactSlippage() public {
        uint256 amountIn = 10e18;

        uint256 amountInWithFee =
            amountIn * 997;

        uint256 expectedOut =
            (
                amountInWithFee *
                1000e18
            ) /
            (
                1000e18 * 1000 +
                amountInWithFee
            );

        vm.prank(trader);

        uint256 amountOut = amm.swap(
            amountIn,
            true,
            expectedOut,
            block.timestamp + 100
        );

        assertEq(
            amountOut,
            expectedOut
        );
    }

    // =============================================================
    //                         REVERT TESTS
    // =============================================================

    function test_Swap_ZeroAmountIn_Reverts() public {
        vm.prank(trader);

        vm.expectRevert(
            SimpleAMM.ZeroAmount.selector
        );

        amm.swap(
            0,
            true,
            0,
            block.timestamp + 100
        );
    }

    function test_Swap_EmptyPool_Reverts() public {
        SimpleAMM emptyAmm =
            new SimpleAMM(
                address(token0),
                address(token1)
            );

        vm.prank(trader);

        vm.expectRevert(
            SimpleAMM.InsufficientLiquidity.selector
        );

        emptyAmm.swap(
            100e18,
            true,
            0,
            block.timestamp + 100
        );
    }

    function test_Swap_InsufficientBalance_Reverts() public {
        vm.prank(trader);

        vm.expectRevert(
            SimpleAMM.InsufficientLiquidity.selector
        );

        amm.swap(
            100_000e18,
            true,
            0,
            block.timestamp + 100
        );
    }

    function test_Swap_ExpiredDeadline_Reverts() public {
        vm.prank(trader);

        vm.expectRevert(
            SimpleAMM.TransactionExpired.selector
        );

        amm.swap(
            10e18,
            true,
            0,
            block.timestamp - 1
        );
    }

    function test_Swap_OutputCannotExceedReserve() public {
        uint256 amountIn = 10e18;

        vm.prank(trader);

        uint256 amountOut = amm.swap(
            amountIn,
            true,
            0,
            block.timestamp + 100
        );

        assertLt(
            amountOut,
            1000e18
        );
    }

    // =============================================================
    //                    RESERVE ACCOUNTING
    // =============================================================

    function test_Swap_UpdatesReservesCorrectly() public {
        uint256 amountIn = 10e18;

        uint256 reserve0Before =
            amm.reserve0();

        uint256 reserve1Before =
            amm.reserve1();

        vm.prank(trader);

        uint256 amountOut = amm.swap(
            amountIn,
            true,
            0,
            block.timestamp + 100
        );

        assertEq(
            amm.reserve0(),
            reserve0Before + amountIn
        );

        assertEq(
            amm.reserve1(),
            reserve1Before - amountOut
        );
    }
}