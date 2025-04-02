// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DerivativesMarket
/// @notice A dynamic, optimized, and secure contract for creating and managing multiple derivative positions.
/// Each position is created by a user who locks collateral, and can be joined by a counterparty with matching collateral.
/// The contract owner (oracle) settles positions after expiry, deciding the winning party.
contract DerivativesMarket is Ownable, ReentrancyGuard {
    /// @notice Enum representing the type of the derivative (e.g., Future, Option, CFD).
    enum DerivativeType { Future, Option, CFD }

    /// @notice Structure representing a derivative position.
    struct Position {
        uint256 id;             // The position ID
        DerivativeType dtype;   // Type of derivative
        address creator;        // The address that created the position
        address counterparty;   // The address that joined the position
        uint256 collateral;     // Collateral required from each party
        uint256 expiry;         // Expiration timestamp
        bool active;            // True if position is active (not settled or canceled)
        bool settled;           // True if position has been settled
    }

    /// @notice Incremental counter for position IDs
    uint256 public nextPositionId;

    /// @notice Mapping of position ID to position details
    mapping(uint256 => Position) public positions;

    /// @notice Mapping of position ID and user address to locked collateral amount
    mapping(uint256 => mapping(address => uint256)) public lockedCollateral;

    // --- Events ---
    event PositionCreated(
        uint256 indexed id,
        DerivativeType dtype,
        address indexed creator,
        uint256 collateral,
        uint256 expiry
    );
    event PositionJoined(uint256 indexed id, address indexed counterparty, uint256 collateral);
    event PositionSettled(uint256 indexed id, address winner, uint256 totalCollateral);
    event PositionCanceled(uint256 indexed id);

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Create a new derivative position. The creator locks their collateral upon creation.
    /// @param dtype The derivative type (Future, Option, CFD, etc.).
    /// @param collateral The amount of collateral each participant must lock (in wei).
    /// @param expiry The expiration timestamp for the position.
    /// @return positionId The unique ID assigned to this newly created position.
    function createPosition(DerivativeType dtype, uint256 collateral, uint256 expiry)
        external
        payable
        nonReentrant
        returns (uint256 positionId)
    {
        require(collateral > 0, "Collateral must be > 0");
        require(msg.value == collateral, "Incorrect collateral amount");
        require(expiry > block.timestamp, "Expiry must be in the future");

        positionId = nextPositionId++;
        positions[positionId] = Position({
            id: positionId,
            dtype: dtype,
            creator: msg.sender,
            counterparty: address(0),
            collateral: collateral,
            expiry: expiry,
            active: true,
            settled: false
        });

        lockedCollateral[positionId][msg.sender] = collateral;

        emit PositionCreated(positionId, dtype, msg.sender, collateral, expiry);
    }

    /// @notice A counterparty joins an existing position by depositing matching collateral.
    /// @param positionId The ID of the position to join.
    function joinPosition(uint256 positionId) external payable nonReentrant {
        Position storage pos = positions[positionId];
        require(pos.active && !pos.settled, "Position not active");
        require(pos.counterparty == address(0), "Position already joined");
        require(block.timestamp < pos.expiry, "Position expired");
        require(msg.value == pos.collateral, "Incorrect collateral amount");

        pos.counterparty = msg.sender;
        lockedCollateral[positionId][msg.sender] = msg.value;

        emit PositionJoined(positionId, msg.sender, msg.value);
    }

    /// @notice The owner (acting as an oracle) settles a position after expiry.
    /// @param positionId The ID of the position to settle.
    /// @param winner The address receiving the entire locked collateral.
    function settlePosition(uint256 positionId, address winner) external nonReentrant onlyOwner {
        Position storage pos = positions[positionId];
        require(pos.active && !pos.settled, "Already settled or inactive");
        require(block.timestamp >= pos.expiry, "Not yet expired");
        require(winner == pos.creator || winner == pos.counterparty, "Winner must be participant");

        pos.active = false;
        pos.settled = true;

        uint256 totalCollateral = lockedCollateral[positionId][pos.creator] +
            lockedCollateral[positionId][pos.counterparty];
        lockedCollateral[positionId][pos.creator] = 0;
        lockedCollateral[positionId][pos.counterparty] = 0;

        (bool success, ) = payable(winner).call{value: totalCollateral}("");
        require(success, "Transfer failed");

        emit PositionSettled(positionId, winner, totalCollateral);
    }

    /// @notice Creator can cancel a position if no counterparty has joined yet.
    /// @param positionId The ID of the position to cancel.
    function cancelPosition(uint256 positionId) external nonReentrant {
        Position storage pos = positions[positionId];
        require(pos.active && !pos.settled, "Position not active");
        require(pos.counterparty == address(0), "Counterparty joined");
        require(msg.sender == pos.creator, "Not position creator");

        pos.active = false;
        uint256 locked = lockedCollateral[positionId][msg.sender];
        lockedCollateral[positionId][msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: locked}("");
        require(success, "Refund transfer failed");

        emit PositionCanceled(positionId);
    }

    /// @notice Retrieve the details of a derivative position by ID.
    /// @param positionId The ID of the position.
    /// @return The Position struct for the given ID.
    function getPosition(uint256 positionId) external view returns (Position memory) {
        return positions[positionId];
    }

    /// @notice Returns total collateral locked by a user in a specific position.
    /// @param positionId The position ID.
    /// @param user The user's address.
    /// @return The amount of collateral locked by the user.
    function getLockedCollateral(uint256 positionId, address user) external view returns (uint256) {
        return lockedCollateral[positionId][user];
    }

    /// @notice Returns the total number of positions ever created (including settled/canceled).
    /// @return The total positions count.
    function totalPositions() external view returns (uint256) {
        return nextPositionId;
    }
}
