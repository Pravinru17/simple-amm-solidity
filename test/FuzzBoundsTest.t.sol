// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleAMM.sol";
import "../src/MockERC20.sol";

contract FuzzBoundsTest is Test {
    SimpleAMM amm;
    MockERC20 token0;
    MockERC20 token1;

    function setUp() public {
        token0 = new MockERC20("Token A", "TKA");
        token1 = new MockERC20("Token B", "TKB");

        amm = new SimpleAMM(
            address(token0),
            address(token1)
        );

        token0.mint(
            address(this),
            10_000e18
        );

        token1.mint(
            address(this),
            10_000e18
        );

        token0.approve(
            address(amm),
            type(uint256).max
        );

        token1.approve(
            address(amm),
            type(uint256).max
        );

        // Seed the pool.
        amm.addLiquidity(
            1000e18,
            1000e18,
            0,
            0,
            block.timestamp + 100
        );

        // Give the test contract plenty of tokens
        // for fuzzing.
        token0.mint(
            address(this),
            100_000_000e18
        );

        token1.mint(
            address(this),
            100_000_000e18
        );
    }

    // =============================================================
    //                         SWAP FUZZING
    // =============================================================

    function testFuzz_Swap(
        uint256 swapAmount
    ) public {
        // 1 wei can produce zero output because of integer
        // division. Start at 1e18 so the swap produces output.
        swapAmount = bound(
            swapAmount,
            1e18,
            amm.reserve0()
        );

        uint256 reserve0Before =
            amm.reserve0();

        uint256 reserve1Before =
            amm.reserve1();

        uint256 kBefore =
            reserve0Before *
            reserve1Before;

        uint256 amountOut =
            amm.swap(
                swapAmount,
                true,
                0,
                block.timestamp + 100
            );

        uint256 reserve0After =
            amm.reserve0();

        uint256 reserve1After =
            amm.reserve1();

        uint256 kAfter =
            reserve0After *
            reserve1After;

        assertGt(
            amountOut,
            0,
            "Output must be greater than zero"
        );

        assertEq(
            reserve0After,
            reserve0Before + swapAmount,
            "Reserve0 math failed"
        );

        assertEq(
            reserve1After,
            reserve1Before - amountOut,
            "Reserve1 math failed"
        );

        // The swap fee should prevent K from decreasing.
        assertGe(
            kAfter,
            kBefore,
            "K decreased"
        );
    }

    function testFuzz_SwapReverse(
        uint256 swapAmount
    ) public {
        swapAmount = bound(
            swapAmount,
            1e18,
            amm.reserve1()
        );

        uint256 reserve0Before =
            amm.reserve0();

        uint256 reserve1Before =
            amm.reserve1();

        uint256 kBefore =
            reserve0Before *
            reserve1Before;

        uint256 amountOut =
            amm.swap(
                swapAmount,
                false,
                0,
                block.timestamp + 100
            );

        uint256 reserve0After =
            amm.reserve0();

        uint256 reserve1After =
            amm.reserve1();

        uint256 kAfter =
            reserve0After *
            reserve1After;

        assertGt(
            amountOut,
            0,
            "Output must be greater than zero"
        );

        assertEq(
            reserve1After,
            reserve1Before + swapAmount,
            "Reserve1 math failed"
        );

        assertEq(
            reserve0After,
            reserve0Before - amountOut,
            "Reserve0 math failed"
        );

        assertGe(
            kAfter,
            kBefore,
            "K decreased"
        );
    }

    // =============================================================
    //                     LIQUIDITY FUZZING
    // =============================================================

    function testFuzz_AddLiquidity(
        uint256 amount
    ) public {
        amount = bound(
            amount,
            1e18,
            100_000e18
        );

        uint256 totalSupplyBefore =
            amm.totalSupply();

        uint256 reserve0Before =
            amm.reserve0();

        uint256 reserve1Before =
            amm.reserve1();

        uint256 liquidity =
            amm.addLiquidity(
                amount,
                amount,
                0,
                0,
                block.timestamp + 100
            );

        assertGt(
            liquidity,
            0,
            "Liquidity minted must be positive"
        );

        assertGt(
            amm.totalSupply(),
            totalSupplyBefore,
            "Total supply must increase"
        );

        assertEq(
            amm.reserve0(),
            reserve0Before + amount
        );

        assertEq(
            amm.reserve1(),
            reserve1Before + amount
        );
    }

    // =============================================================
    //                       OUTPUT BOUNDS
    // =============================================================

    function testFuzz_SwapOutputNeverExceedsReserve(
        uint256 swapAmount
    ) public {
        swapAmount = bound(
            swapAmount,
            1e18,
            amm.reserve0()
        );

        uint256 reserve1Before =
            amm.reserve1();

        uint256 amountOut =
            amm.swap(
                swapAmount,
                true,
                0,
                block.timestamp + 100
            );

        assertGt(
            amountOut,
            0,
            "Output must be greater than zero"
        );

        assertLt(
            amountOut,
            reserve1Before,
            "Output cannot exceed reserve"
        );
    }

    // =============================================================
    //                    K MONOTONICITY FUZZ
    // =============================================================

    function testFuzz_KNeverDecreases(
        uint256 swapAmount
    ) public {
        swapAmount = bound(
            swapAmount,
            1e18,
            amm.reserve0()
        );

        uint256 kBefore =
            amm.reserve0() *
            amm.reserve1();

        amm.swap(
            swapAmount,
            true,
            0,
            block.timestamp + 100
        );

        uint256 kAfter =
            amm.reserve0() *
            amm.reserve1();

        assertGe(
            kAfter,
            kBefore,
            "Constant product decreased"
        );
    }
}