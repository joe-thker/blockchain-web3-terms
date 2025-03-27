// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Import IERC20 interface
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice ConcentratedLiquidityPool allows liquidity providers to deposit token0 and token1
/// and concentrate their liquidity in a specified tick range (price range). This example
/// calculates liquidity in a simplified manner (using the minimum of the provided amounts).
contract ConcentratedLiquidityPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token0;
    IERC20 public immutable token1;

    // For simplicity, we represent price as a "tick" (an integer)
    uint256 public currentTick;

    // Each liquidity position is represented by a unique ID.
    struct Position {
        uint256 id;
        address owner;
        int24 lowerTick;
        int24 upperTick;
        uint256 amount0;
        uint256 amount1;
        uint256 liquidity;
    }

    // Mapping from position ID to Position details.
    mapping(uint256 => Position) public positions;
    uint256 public nextPositionId;

    event LiquidityAdded(
        uint256 indexed positionId,
        address indexed owner,
        int24 lowerTick,
        int24 upperTick,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );
    event LiquidityRemoved(
        uint256 indexed positionId,
        address indexed owner,
        uint256 amount0,
        uint256 amount1
    );
    event CurrentTickUpdated(uint256 newTick);

    /// @notice Constructor sets the addresses for token0 and token1 and an initial tick.
    /// @param _token0 Address of the first token.
    /// @param _token1 Address of the second token.
    /// @param _initialTick The initial price tick.
    constructor(address _token0, address _token1, uint256 _initialTick)
        Ownable(msg.sender) // Pass msg.sender to Ownable base constructor
    {
        require(_token0 != address(0) && _token1 != address(0), "Invalid token address");
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        currentTick = _initialTick;
        nextPositionId = 1;
    }

    /// @notice Internal helper to compute liquidity in a simplified manner.
    /// For example, we use the minimum of the two token amounts.
    function _calculateLiquidity(uint256 amount0, uint256 amount1) internal pure returns (uint256) {
        return amount0 < amount1 ? amount0 : amount1;
    }

    /// @notice Allows a user to add liquidity within a specified tick range.
    /// The user must have approved this contract to transfer the tokens.
    /// @param lowerTick The lower bound of the tick range.
    /// @param upperTick The upper bound of the tick range.
    /// @param amount0 The amount of token0 to deposit.
    /// @param amount1 The amount of token1 to deposit.
    /// @return positionId The unique ID of the created liquidity position.
    function addLiquidity(
        int24 lowerTick,
        int24 upperTick,
        uint256 amount0,
        uint256 amount1
    ) external nonReentrant returns (uint256 positionId) {
        require(lowerTick < upperTick, "Invalid tick range");
        require(amount0 > 0 && amount1 > 0, "Amounts must be > 0");

        // Transfer tokens from the provider to this contract.
        token0.safeTransferFrom(msg.sender, address(this), amount0);
        token1.safeTransferFrom(msg.sender, address(this), amount1);

        uint256 liquidity = _calculateLiquidity(amount0, amount1);

        positionId = nextPositionId++;
        positions[positionId] = Position({
            id: positionId,
            owner: msg.sender,
            lowerTick: lowerTick,
            upperTick: upperTick,
            amount0: amount0,
            amount1: amount1,
            liquidity: liquidity
        });

        emit LiquidityAdded(positionId, msg.sender, lowerTick, upperTick, amount0, amount1, liquidity);
    }

    /// @notice Allows the owner of a liquidity position to remove their liquidity.
    /// The position is deleted and the deposited tokens are returned.
    /// @param positionId The ID of the position to remove.
    function removeLiquidity(uint256 positionId) external nonReentrant {
        Position memory pos = positions[positionId];
        require(pos.owner == msg.sender, "Not position owner");
        require(pos.liquidity > 0, "Position already removed");

        // Remove the position.
        delete positions[positionId];

        // Transfer tokens back to the liquidity provider.
        token0.safeTransfer(msg.sender, pos.amount0);
        token1.safeTransfer(msg.sender, pos.amount1);

        emit LiquidityRemoved(positionId, msg.sender, pos.amount0, pos.amount1);
    }

    /// @notice Updates the current tick (price). Only the owner can update the tick.
    /// @param newTick The new tick value.
    function updateCurrentTick(uint256 newTick) external onlyOwner {
        currentTick = newTick;
        emit CurrentTickUpdated(newTick);
    }
}
