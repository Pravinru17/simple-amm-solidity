// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";

/// @title SimpleAMM
/// @notice Constant-product automated market maker for two ERC20 tokens.
/// @dev Educational implementation inspired by the core mechanics of Uniswap V2.
contract SimpleAMM {
    // =============================================================
    //                           CONSTANTS
    // =============================================================

    uint256 public constant MINIMUM_LIQUIDITY = 1000;
    uint256 public constant FEE_NUMERATOR = 997;
    uint256 public constant FEE_DENOMINATOR = 1000;

    // =============================================================
    //                         STATE VARIABLES
    // =============================================================

    address public immutable token0;
    address public immutable token1;

    uint256 public reserve0;
    uint256 public reserve1;

    uint32 public blockTimestampLast;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // =============================================================
    //                             EVENTS
    // =============================================================

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

    event Mint(
        address indexed sender,
        uint256 amount0,
        uint256 amount1
    );

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );

    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    event Sync(
        uint256 reserve0,
        uint256 reserve1
    );

    // =============================================================
    //                              ERRORS
    // =============================================================

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

    // =============================================================
    //                         REENTRANCY
    // =============================================================

    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private reentrancyStatus = NOT_ENTERED;

    modifier nonReentrant() {
        if (reentrancyStatus == ENTERED) {
            revert Reentrancy();
        }

        reentrancyStatus = ENTERED;
        _;
        reentrancyStatus = NOT_ENTERED;
    }

    // =============================================================
    //                         CONSTRUCTOR
    // =============================================================

    constructor(
        address _token0,
        address _token1
    ) {
        if (
            _token0 == address(0) ||
            _token1 == address(0) ||
            _token0 == _token1
        ) {
            revert InvalidTokens();
        }

        token0 = _token0;
        token1 = _token1;
    }

    // =============================================================
    //                       ERC20-LIKE FUNCTIONS
    // =============================================================

    function approve(
        address spender,
        uint256 amount
    ) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) external returns (bool) {
        if (balanceOf[msg.sender] < amount) {
            revert InsufficientLPBalance();
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
    ) external returns (bool) {
        if (balanceOf[from] < amount) {
            revert InsufficientLPBalance();
        }

        if (allowance[from][msg.sender] < amount) {
            revert InsufficientLPAllowance();
        }

        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Approval(
            from,
            msg.sender,
            allowance[from][msg.sender]
        );

        emit Transfer(from, to, amount);

        return true;
    }

    // =============================================================
    //                       ADD LIQUIDITY
    // =============================================================

    /// @notice Add liquidity to the pool and receive LP tokens.
    /// @param amount0Desired Desired amount of token0.
    /// @param amount1Desired Desired amount of token1.
    /// @param amount0Min Minimum acceptable token0 amount.
    /// @param amount1Min Minimum acceptable token1 amount.
    /// @param deadline Transaction deadline.
    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline
    )
        external
        nonReentrant
        returns (uint256 liquidity)
    {
        if (block.timestamp > deadline) {
            revert TransactionExpired();
        }

        if (
            amount0Desired == 0 ||
            amount1Desired == 0
        ) {
            revert ZeroAmount();
        }

        uint256 amount0;
        uint256 amount1;

        if (reserve0 == 0 && reserve1 == 0) {
            amount0 = amount0Desired;
            amount1 = amount1Desired;
        } else {
            uint256 amount1Optimal =
                (amount0Desired * reserve1) / reserve0;

            if (amount1Optimal <= amount1Desired) {
                if (amount1Optimal < amount1Min) {
                    revert SlippageExceeded();
                }

                amount0 = amount0Desired;
                amount1 = amount1Optimal;
            } else {
                uint256 amount0Optimal =
                    (amount1Desired * reserve0) / reserve1;

                if (amount0Optimal < amount0Min) {
                    revert SlippageExceeded();
                }

                amount0 = amount0Optimal;
                amount1 = amount1Desired;
            }
        }

        if (
            amount0 < amount0Min ||
            amount1 < amount1Min
        ) {
            revert SlippageExceeded();
        }

        _safeTransferFrom(
            token0,
            msg.sender,
            address(this),
            amount0
        );

        _safeTransferFrom(
            token1,
            msg.sender,
            address(this),
            amount1
        );

        uint256 _totalSupply = totalSupply;

        if (_totalSupply == 0) {
            uint256 rootK = sqrt(amount0 * amount1);

            if (rootK <= MINIMUM_LIQUIDITY) {
                revert InsufficientLiquidity();
            }

            liquidity = rootK - MINIMUM_LIQUIDITY;

            _mint(
                address(0),
                MINIMUM_LIQUIDITY
            );
        } else {
            uint256 liquidity0 =
                (amount0 * _totalSupply) / reserve0;

            uint256 liquidity1 =
                (amount1 * _totalSupply) / reserve1;

            liquidity = min(
                liquidity0,
                liquidity1
            );
        }

        if (liquidity == 0) {
            revert InsufficientLiquidity();
        }

        _mint(msg.sender, liquidity);

        _update(
            reserve0 + amount0,
            reserve1 + amount1
        );

        emit Mint(
            msg.sender,
            amount0,
            amount1
        );
    }

    // =============================================================
    //                       REMOVE LIQUIDITY
    // =============================================================

    /// @notice Burn LP tokens and receive proportional pool assets.
    /// @param liquidity Amount of LP tokens to burn.
    /// @param amount0Min Minimum token0 amount expected.
    /// @param amount1Min Minimum token1 amount expected.
    /// @param deadline Transaction deadline.
    function removeLiquidity(
        uint256 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline
    )
        external
        nonReentrant
        returns (
            uint256 amount0,
            uint256 amount1
        )
    {
        if (block.timestamp > deadline) {
            revert TransactionExpired();
        }

        if (liquidity == 0) {
            revert ZeroAmount();
        }

        if (balanceOf[msg.sender] < liquidity) {
            revert InsufficientLPBalance();
        }

        uint256 _totalSupply = totalSupply;

        amount0 =
            (liquidity * reserve0) /
            _totalSupply;

        amount1 =
            (liquidity * reserve1) /
            _totalSupply;

        if (
            amount0 < amount0Min ||
            amount1 < amount1Min
        ) {
            revert SlippageExceeded();
        }

        if (
            amount0 == 0 ||
            amount1 == 0
        ) {
            revert InsufficientLiquidity();
        }

        _burn(msg.sender, liquidity);

        _safeTransfer(
            token0,
            msg.sender,
            amount0
        );

        _safeTransfer(
            token1,
            msg.sender,
            amount1
        );

        _update(
            reserve0 - amount0,
            reserve1 - amount1
        );

        emit Burn(
            msg.sender,
            amount0,
            amount1,
            msg.sender
        );
    }

    // =============================================================
    //                              SWAP
    // =============================================================

    /// @notice Swap one token for the other using the x*y=k invariant.
    /// @param amountIn Input token amount.
    /// @param zeroForOne True for token0 -> token1.
    /// @param amountOutMin Minimum acceptable output amount.
    /// @param deadline Transaction deadline.
    function swap(
        uint256 amountIn,
        bool zeroForOne,
        uint256 amountOutMin,
        uint256 deadline
    )
        external
        nonReentrant
        returns (uint256 amountOut)
    {
        if (block.timestamp > deadline) {
            revert TransactionExpired();
        }

        if (amountIn == 0) {
            revert ZeroAmount();
        }

        if (
            reserve0 == 0 ||
            reserve1 == 0
        ) {
            revert InsufficientLiquidity();
        }

        uint256 reserveIn;
        uint256 reserveOut;
        address tokenIn;
        address tokenOut;

        if (zeroForOne) {
            reserveIn = reserve0;
            reserveOut = reserve1;
            tokenIn = token0;
            tokenOut = token1;
        } else {
            reserveIn = reserve1;
            reserveOut = reserve0;
            tokenIn = token1;
            tokenOut = token0;
        }

        uint256 amountInWithFee =
            amountIn * FEE_NUMERATOR;

        amountOut =
            (amountInWithFee * reserveOut) /
            (
                reserveIn * FEE_DENOMINATOR +
                amountInWithFee
            );

        if (amountOut == 0) {
            revert InsufficientOutputAmount();
        }

        if (amountOut > reserveOut) {
            revert InsufficientLiquidity();
        }

        if (amountOut < amountOutMin) {
            revert SlippageExceeded();
        }

        _safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            amountIn
        );

        _safeTransfer(
            tokenOut,
            msg.sender,
            amountOut
        );

        uint256 newReserve0;
        uint256 newReserve1;

        if (zeroForOne) {
            newReserve0 = reserve0 + amountIn;
            newReserve1 = reserve1 - amountOut;
        } else {
            newReserve0 = reserve0 - amountOut;
            newReserve1 = reserve1 + amountIn;
        }

        _update(
            newReserve0,
            newReserve1
        );

        emit Swap(
            msg.sender,
            zeroForOne ? amountIn : 0,
            zeroForOne ? 0 : amountIn,
            zeroForOne ? 0 : amountOut,
            zeroForOne ? amountOut : 0,
            msg.sender
        );
    }

    // =============================================================
    //                       INTERNAL FUNCTIONS
    // =============================================================

    /// @notice Safely transfer an ERC20 token.
    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(
                abi.encodeWithSelector(
                    IERC20.transfer.selector,
                    to,
                    value
                )
            );

        if (
            !success ||
            (
                data.length > 0 &&
                !abi.decode(data, (bool))
            )
        ) {
            revert InsufficientLiquidity();
        }
    }

    /// @notice Safely transferFrom an ERC20 token.
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(
                abi.encodeWithSelector(
                    IERC20.transferFrom.selector,
                    from,
                    to,
                    value
                )
            );

        if (
            !success ||
            (
                data.length > 0 &&
                !abi.decode(data, (bool))
            )
        ) {
            revert InsufficientLiquidity();
        }
    }

    /// @notice Update stored reserves.
    /// @dev Reserves are explicitly tracked rather than read from balanceOf().
    function _update(
        uint256 balance0,
        uint256 balance1
    ) private {
        reserve0 = balance0;
        reserve1 = balance1;

        blockTimestampLast =
            uint32(block.timestamp % 2 ** 32);

        emit Sync(
            balance0,
            balance1
        );
    }

    /// @notice Mint LP tokens.
    function _mint(
        address to,
        uint256 amount
    ) private {
        totalSupply += amount;
        balanceOf[to] += amount;

        emit Transfer(
            address(0),
            to,
            amount
        );
    }

    /// @notice Burn LP tokens.
    function _burn(
        address from,
        uint256 amount
    ) private {
        balanceOf[from] -= amount;
        totalSupply -= amount;

        emit Transfer(
            from,
            address(0),
            amount
        );
    }

    /// @notice Babylonian square-root implementation.
    function sqrt(
        uint256 y
    ) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;

            uint256 x = y / 2 + 1;

            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /// @notice Return the smaller of two values.
    function min(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
