// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/SimpleAMM.sol";
import "../src/MockERC20.sol";

/// @title Handler
/// @notice Executes randomized AMM actions for invariant testing.
/// @dev Foundry's invariant engine calls these functions with fuzzed inputs.
contract Handler {
    SimpleAMM public amm;
    MockERC20 public token0;
    MockERC20 public token1;

    address public actor;

    uint256 public k;

    constructor(
        address _amm,
        address _token0,
        address _token1
    ) {
        amm = SimpleAMM(_amm);
        token0 = MockERC20(_token0);
        token1 = MockERC20(_token1);

        actor = address(this);

        token0.mint(
            actor,
            1_000_000_000e18
        );

        token1.mint(
            actor,
            1_000_000_000e18
        );

        token0.approve(
            address(amm),
            type(uint256).max
        );

        token1.approve(
            address(amm),
            type(uint256).max
        );
    }

    // =============================================================
    //                    RANDOMIZED ACTIONS
    // =============================================================

    function add_liquidity(
        uint256 amount
    ) public {
        amount = _bound(
            amount,
            1e18,
            1_000_000e18
        );

        try amm.addLiquidity(
            amount,
            amount,
            0,
            0,
            block.timestamp + 100
        ) {
        } catch {
        }
    }

    function swap_0_for_1(
        uint256 amount
    ) public {
        uint256 reserve0 = amm.reserve0();

        if (reserve0 == 0) {
            return;
        }

        amount = _bound(
            amount,
            1,
            reserve0
        );

        try amm.swap(
            amount,
            true,
            0,
            block.timestamp + 100
        ) {
        } catch {
        }
    }

    function swap_1_for_0(
        uint256 amount
    ) public {
        uint256 reserve1 = amm.reserve1();

        if (reserve1 == 0) {
            return;
        }

        amount = _bound(
            amount,
            1,
            reserve1
        );

        try amm.swap(
            amount,
            false,
            0,
            block.timestamp + 100
        ) {
        } catch {
        }
    }

    function remove_liquidity(
        uint256 amount
    ) public {
        uint256 lpBalance =
            amm.balanceOf(actor);

        if (lpBalance == 0) {
            return;
        }

        amount = _bound(
            amount,
            1,
            lpBalance
        );

        try amm.removeLiquidity(
            amount,
            0,
            0,
            block.timestamp + 100
        ) {
        } catch {
        }
    }

    // =============================================================
    //                     INVARIANT HELPERS
    // =============================================================

    function setK(
        uint256 _k
    ) external {
        k = _k;
    }

    function totalToken0()
        public
        view
        returns (uint256)
    {
        return
            token0.balanceOf(actor) +
            token0.balanceOf(address(amm));
    }

    function totalToken1()
        public
        view
        returns (uint256)
    {
        return
            token1.balanceOf(actor) +
            token1.balanceOf(address(amm));
    }

    function currentK()
        public
        view
        returns (uint256)
    {
        return
            amm.reserve0() *
            amm.reserve1();
    }

    // =============================================================
    //                         INTERNAL
    // =============================================================

    /// @notice Bound a fuzzed value without depending on forge-std.
    function _bound(
        uint256 value,
        uint256 minValue,
        uint256 maxValue
    ) internal pure returns (uint256) {
        if (maxValue < minValue) {
            return minValue;
        }

        if (value >= minValue && value <= maxValue) {
            return value;
        }

        uint256 range =
            maxValue - minValue + 1;

        return
            minValue +
            (value % range);
    }
}