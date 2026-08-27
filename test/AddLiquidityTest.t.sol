// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleAMM.sol";
import "../src/MockERC20.sol";

contract AddLiquidityTest is Test {
    SimpleAMM amm;
    MockERC20 token0;
    MockERC20 token1;

    address lp1 = address(0x1);
    address lp2 = address(0x2);

    function setUp() public {
        token0 = new MockERC20("Token A", "TKA");
        token1 = new MockERC20("Token B", "TKB");

        amm = new SimpleAMM(
            address(token0),
            address(token1)
        );

        token0.mint(lp1, 1_000_000e18);
        token1.mint(lp1, 1_000_000e18);

        token0.mint(lp2, 1_000_000e18);
        token1.mint(lp2, 1_000_000e18);

        vm.startPrank(lp1);

        token0.approve(
            address(amm),
            type(uint256).max
        );

        token1.approve(
            address(amm),
            type(uint256).max
        );

        vm.stopPrank();

        vm.startPrank(lp2);

        token0.approve(
            address(amm),
            type(uint256).max
        );

        token1.approve(
            address(amm),
            type(uint256).max
        );

        vm.stopPrank();
    }

    // =============================================================
    //                    FIRST LIQUIDITY
    // =============================================================

    function test_AddLiquidity_FirstDeposit() public {
        uint256 amount0 = 1000e18;
        uint256 amount1 = 1000e18;

        vm.prank(lp1);

        uint256 liquidity = amm.addLiquidity(
            amount0,
            amount1,
            0,
            0,
            block.timestamp + 100
        );

        assertEq(
            liquidity,
            1000e18 - amm.MINIMUM_LIQUIDITY()
        );

        assertEq(
            amm.reserve0(),
            amount0
        );

        assertEq(
            amm.reserve1(),
            amount1
        );

        assertEq(
            amm.balanceOf(lp1),
            liquidity
        );

        assertEq(
            amm.totalSupply(),
            liquidity + amm.MINIMUM_LIQUIDITY()
        );
    }

    function test_AddLiquidity_LocksMinimumLiquidity() public {
        vm.prank(lp1);

        amm.addLiquidity(
            1000e18,
            1000e18,
            0,
            0,
            block.timestamp + 100
        );

        assertEq(
            amm.balanceOf(address(0)),
            amm.MINIMUM_LIQUIDITY()
        );
    }

    // =============================================================
    //                    MULTIPLE LIQUIDITY
    // =============================================================

    function test_AddLiquidity_SecondDeposit() public {
        vm.prank(lp1);

        amm.addLiquidity(
            1000e18,
            1000e18,
            0,
            0,
            block.timestamp + 100
        );

        vm.prank(lp2);

        uint256 liquidity = amm.addLiquidity(
            1000e18,
            1000e18,
            0,
            0,
            block.timestamp + 100
        );

        assertEq(
            liquidity,
            1000e18
        );

        assertEq(
            amm.reserve0(),
            2000e18
        );

        assertEq(
            amm.reserve1(),
            2000e18
        );

        assertEq(
            amm.balanceOf(lp2),
            1000e18
        );
    }

    function test_AddLiquidity_UsesOptimalRatio() public {
        vm.prank(lp1);

        amm.addLiquidity(
            1000e18,
            1000e18,
            0,
            0,
            block.timestamp + 100
        );

        vm.prank(lp2);

        uint256 liquidity = amm.addLiquidity(
            2000e18,
            1000e18,
            0,
            0,
            block.timestamp + 100
        );

        assertEq(
            liquidity,
            1000e18
        );

        assertEq(
            amm.reserve0(),
            2000e18
        );

        assertEq(
            amm.reserve1(),
            2000e18
        );

        // Only 1000 token0 should have been used.
        assertEq(
            token0.balanceOf(lp2),
            1_000_000e18 - 1000e18
        );

        assertEq(
            token1.balanceOf(lp2),
            1_000_000e18 - 1000e18
        );
    }

    // =============================================================
    //                         REVERT TESTS
    // =============================================================

    function test_AddLiquidity_ZeroAmount_Reverts() public {
        vm.prank(lp1);

        vm.expectRevert(
            SimpleAMM.ZeroAmount.selector
        );

        amm.addLiquidity(
            0,
            1000e18,
            0,
            0,
            block.timestamp + 100
        );
    }

    function test_AddLiquidity_ExpiredDeadline_Reverts() public {
        vm.prank(lp1);

        vm.expectRevert(
            SimpleAMM.TransactionExpired.selector
        );

        amm.addLiquidity(
            1000e18,
            1000e18,
            0,
            0,
            block.timestamp - 1
        );
    }

    function test_AddLiquidity_SlippageExceeded_Reverts() public {
        vm.prank(lp1);

        vm.expectRevert(
            SimpleAMM.SlippageExceeded.selector
        );

        amm.addLiquidity(
            1000e18,
            1000e18,
            1001e18,
            0,
            block.timestamp + 100
        );
    }

    function test_AddLiquidity_TooSmallFirstDeposit_Reverts() public {
        vm.prank(lp1);

        vm.expectRevert(
            SimpleAMM.InsufficientLiquidity.selector
        );

        amm.addLiquidity(
            1000,
            1000,
            0,
            0,
            block.timestamp + 100
        );
    }

    // =============================================================
    //                         FUZZ TESTS
    // =============================================================

    function testFuzz_FirstDeposit_SqrtFormula(
        uint256 amount
    ) public {
        amount = bound(
            amount,
            1e18,
            1_000_000e18
        );

        vm.prank(lp1);

        uint256 lpTokens = amm.addLiquidity(
            amount,
            amount,
            0,
            0,
            block.timestamp + 100
        );

        assertEq(
            lpTokens,
            amount - amm.MINIMUM_LIQUIDITY(),
            "LP calculation is incorrect"
        );
    }

    function testFuzz_MultipleLPs_TotalSupplyCorrect(
        uint256 deposit1,
        uint256 deposit2
    ) public {
        deposit1 = bound(
            deposit1,
            100e18,
            5_000e18
        );

        deposit2 = bound(
            deposit2,
            100e18,
            5_000e18
        );

        vm.prank(lp1);

        uint256 lp1Tokens = amm.addLiquidity(
            deposit1,
            deposit1,
            0,
            0,
            block.timestamp + 100
        );

        vm.prank(lp2);

        uint256 lp2Tokens = amm.addLiquidity(
            deposit2,
            deposit2,
            0,
            0,
            block.timestamp + 100
        );

        assertEq(
            amm.totalSupply(),
            lp1Tokens +
                lp2Tokens +
                amm.MINIMUM_LIQUIDITY(),
            "Total LP supply is incorrect"
        );
    }
}