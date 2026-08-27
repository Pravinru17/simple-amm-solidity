// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleAMM.sol";
import "../src/MockERC20.sol";

contract RemoveLiquidityTest is Test {
    SimpleAMM amm;
    MockERC20 token0;
    MockERC20 token1;

    address lp = address(0x1);

    function setUp() public {
        token0 = new MockERC20("Token A", "TKA");
        token1 = new MockERC20("Token B", "TKB");

        amm = new SimpleAMM(
            address(token0),
            address(token1)
        );

        token0.mint(
            lp,
            10_000e18
        );

        token1.mint(
            lp,
            10_000e18
        );

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
    //                    BASIC REMOVE TEST
    // =============================================================

    function test_RemoveLiquidity_ReturnsCorrectAmounts()
        public
    {
        uint256 lpBalance =
            amm.balanceOf(lp);

        uint256 amountToRemove =
            lpBalance / 2;

        vm.prank(lp);

        (
            uint256 amount0,
            uint256 amount1
        ) = amm.removeLiquidity(
            amountToRemove,
            0,
            0,
            block.timestamp + 100
        );

        assertEq(
            amount0,
            499999999999999999500
        );

        assertEq(
            amount1,
            499999999999999999500
        );
    }

    // =============================================================
    //                       STATE UPDATES
    // =============================================================

    function test_RemoveLiquidity_UpdatesState()
        public
    {
        uint256 lpBalance =
            amm.balanceOf(lp);

        uint256 bal0Before =
            token0.balanceOf(lp);

        uint256 bal1Before =
            token1.balanceOf(lp);

        vm.prank(lp);

        (
            uint256 amount0,
            uint256 amount1
        ) = amm.removeLiquidity(
            lpBalance,
            0,
            0,
            block.timestamp + 100
        );

        assertEq(
            amm.balanceOf(lp),
            0
        );

        assertEq(
            amm.totalSupply(),
            amm.MINIMUM_LIQUIDITY()
        );

        assertEq(
            amm.reserve0(),
            amm.MINIMUM_LIQUIDITY()
        );

        assertEq(
            amm.reserve1(),
            amm.MINIMUM_LIQUIDITY()
        );

        assertEq(
            token0.balanceOf(lp),
            bal0Before + amount0
        );

        assertEq(
            token1.balanceOf(lp),
            bal1Before + amount1
        );

        assertEq(
            amount0,
            999999999999999999000
        );

        assertEq(
            amount1,
            999999999999999999000
        );
    }

    // =============================================================
    //                  FULL LIQUIDITY REMOVAL
    // =============================================================

    function test_RemoveLiquidity_ReturnsAllUserLiquidity()
        public
    {
        uint256 lpBalance =
            amm.balanceOf(lp);

        uint256 token0Before =
            token0.balanceOf(lp);

        uint256 token1Before =
            token1.balanceOf(lp);

        vm.prank(lp);

        (
            uint256 amount0,
            uint256 amount1
        ) = amm.removeLiquidity(
            lpBalance,
            0,
            0,
            block.timestamp + 100
        );

        assertEq(
            amount0,
            999999999999999999000
        );

        assertEq(
            amount1,
            999999999999999999000
        );

        assertEq(
            token0.balanceOf(lp),
            token0Before + amount0
        );

        assertEq(
            token1.balanceOf(lp),
            token1Before + amount1
        );
    }

    // =============================================================
    //                         REVERT TESTS
    // =============================================================

    function test_RemoveLiquidity_ZeroAmount_Reverts()
        public
    {
        vm.prank(lp);

        vm.expectRevert(
            SimpleAMM.ZeroAmount.selector
        );

        amm.removeLiquidity(
            0,
            0,
            0,
            block.timestamp + 100
        );
    }

    function test_RemoveLiquidity_CannotRemoveMoreThanBalance()
        public
    {
        uint256 lpBalance =
            amm.balanceOf(lp);

        vm.prank(lp);

        vm.expectRevert(
            SimpleAMM.InsufficientLPBalance.selector
        );

        amm.removeLiquidity(
            lpBalance + 1,
            0,
            0,
            block.timestamp + 100
        );
    }

    function test_RemoveLiquidity_SlippageProtection()
        public
    {
        uint256 lpBalance =
            amm.balanceOf(lp);

        vm.prank(lp);

        vm.expectRevert(
            SimpleAMM.SlippageExceeded.selector
        );

        amm.removeLiquidity(
            lpBalance,
            1000e18,
            0,
            block.timestamp + 100
        );
    }

    function test_RemoveLiquidity_ExpiredDeadline()
        public
    {
        uint256 lpBalance =
            amm.balanceOf(lp);

        vm.prank(lp);

        vm.expectRevert(
            SimpleAMM.TransactionExpired.selector
        );

        amm.removeLiquidity(
            lpBalance,
            0,
            0,
            block.timestamp - 1
        );
    }

    // =============================================================
    //                    RESERVE ACCOUNTING
    // =============================================================

    function test_RemoveLiquidity_ReservesDecreaseCorrectly()
        public
    {
        uint256 lpBalance =
            amm.balanceOf(lp);

        uint256 reserve0Before =
            amm.reserve0();

        uint256 reserve1Before =
            amm.reserve1();

        vm.prank(lp);

        (
            uint256 amount0,
            uint256 amount1
        ) = amm.removeLiquidity(
            lpBalance / 2,
            0,
            0,
            block.timestamp + 100
        );

        assertEq(
            amm.reserve0(),
            reserve0Before - amount0
        );

        assertEq(
            amm.reserve1(),
            reserve1Before - amount1
        );
    }
}