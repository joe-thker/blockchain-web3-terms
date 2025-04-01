// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DerivativeContract
/// @notice A dynamic, optimized, and secure contract for creating and managing simplified derivative positions.
/// Two parties lock collateral for a position. Once the derivative expires, the contract owner (oracle) settles
/// it, transferring collateral to the winning party.
contract DerivativeContract is Ownable, ReentrancyGuard {
    /// @notice Represents the derivative type (Future, Option, CFD, etc.).
    enum DerivativeType { Future, Option, CFD }

    /// @notice Data structure for storing a derivative position.
    struct Position {
        uint256 id;           // The position ID.
        DerivativeType dtype; // The type of derivative (e.g., Future, Option, CFD).
        address creator;      // Address that created the position.
        address counterparty; // Address that joined the position.
        uint256 collateral;   // Collateral locked by each party (in wei).
        uint256 expiry;       // Expiration timestamp.
        bool active;          // True if position is active (not canceled or settled).
        bool settled;         // True if position is settled.
    }

    // Incrementing ID for positions.
    uint256 public nextPositionId;
    // Mapping of position ID to position details.
    mapping(uint256 => Position) public positions;
    // Mapping from position ID and user address to their locked collateral amount.
    mapping(uint256 => mapping(address => uint256)) public lockedCollateral;

    // --- Events ---
    event PositionCreated(uint256 indexed id, DerivativeType dtype, address indexed creator, uint256 collateral, uint256 expiry);
    event PositionJoined(uint256 indexed id, address indexed counterparty, uint256 collateral);
    event PositionSettled(uint256 indexed id, address winner, uint256 totalCollateral);
    event PositionCanceled(uint256 indexed id);

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Create a derivative position, specifying type, required collateral, and expiry.
    /// The creator locks their collateral in this function.
    /// @param dtype The type of derivative (Future, Option, CFD, etc.).
    /// @param collateral The amount of collateral each participant must provide (in wei).
    /// @param expiry The expiration timestamp for the position.
    /// @return positionId The unique ID assigned to the newly created position.
    function createPosition(DerivativeType dtype, uint256 collateral, uint256 expiry)
        external
        payable
        nonReentrant
        returns (uint256 positionId)
    {
        require(collateral > 0, "Collateral must be > 0");
        require(msg.value == collateral, "Incorrect collateral amount sent");
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

    /// @notice A counterparty joins an existing position by providing the same amount of collateral.
    /// @param positionId The ID of the position to join.
    function joinPosition(uint256 positionId) external payable nonReentrant {
        Position storage pos = positions[positionId];
        require(pos.active && !pos.settled, "Position not active");
        require(pos.counterparty == address(0), "Position already joined");
        require(block.timestamp < pos.expiry, "Position expired");
        require(msg.value == pos.collateral, "Incorrect collateral amount sent");

        pos.counterparty = msg.sender;
        lockedCollateral[positionId][msg.sender] = msg.value;

        emit PositionJoined(positionId, msg.sender, msg.value);
    }

    /// @notice The owner (acting as an oracle) settles the position after expiry, determining the winner.
    /// @param positionId The ID of the position to settle.
    /// @param winner The address that wins the entire collateral (must be either creator or counterparty).
    function settlePosition(uint256 positionId, address winner) external nonReentrant onlyOwner {
        Position storage pos = positions[positionId];
        require(pos.active && !pos.settled, "Position not active or already settled");
        require(block.timestamp >= pos.expiry, "Not expired yet");
        require(winner == pos.creator || winner == pos.counterparty, "Winner must be a participant");

        pos.active = false;
        pos.settled = true;

        // Calculate total collateral and transfer to the winner.
        uint256 totalCollateral = lockedCollateral[positionId][pos.creator] + lockedCollateral[positionId][pos.counterparty];
        lockedCollateral[positionId][pos.creator] = 0;
        lockedCollateral[positionId][pos.counterparty] = 0;

        (bool success, ) = payable(winner).call{value: totalCollateral}("");
        require(success, "Transfer failed");

        emit PositionSettled(positionId, winner, totalCollateral);
    }

    /// @notice The creator can cancel the position if no counterparty has joined yet.
    /// @param positionId The ID of the position to cancel.
    function cancelPosition(uint256 positionId) external nonReentrant {
        Position storage pos = positions[positionId];
        require(pos.active && !pos.settled, "Position not active");
        require(pos.counterparty == address(0), "Counterparty already joined");
        require(msg.sender == pos.creator, "Not position creator");

        pos.active = false;

        uint256 locked = lockedCollateral[positionId][msg.sender];
        lockedCollateral[positionId][msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: locked}("");
        require(success, "Refund transfer failed");

        emit PositionCanceled(positionId);
    }

    /// @notice Retrieve details of a derivative position by ID.
    function getPosition(uint256 positionId) external view returns (Position memory) {
        return positions[positionId];
    }

    /// @notice Returns total collateral locked by a user in a specific position.
    /// @param positionId The position ID.
    /// @param user The user's address.
    function getLockedCollateral(uint256 positionId, address user) external view returns (uint256) {
        return lockedCollateral[positionId][user];
    }

    /// @notice Returns the total number of positions ever created (including canceled or settled).
    function totalPositions() external view returns (uint256) {
        return nextPositionId;
    }
}
