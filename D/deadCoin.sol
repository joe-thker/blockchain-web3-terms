// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DeadCoinRegistry
/// @notice Manages a dynamic registry of "Dead Coins," including reasons for inactivity.
contract DeadCoinRegistry is Ownable, ReentrancyGuard {

    /// @notice Struct to store details of a dead coin.
    struct DeadCoin {
        uint256 id;
        string name;
        string symbol;
        string reason;
        uint256 dateDeclaredDead; // timestamp
        bool exists;
    }

    // Incremental ID counter for dead coins.
    uint256 public nextDeadCoinId;

    // Mapping from coin ID to details.
    mapping(uint256 => DeadCoin) private deadCoins;

    // Array of dead coin IDs for enumeration.
    uint256[] private deadCoinIds;

    // Events
    event DeadCoinAdded(uint256 indexed id, string name, string symbol);
    event DeadCoinUpdated(uint256 indexed id, string name, string symbol, string reason);
    event DeadCoinRemoved(uint256 indexed id);

    /// @notice Constructor sets deployer as initial owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Adds a new dead coin entry dynamically.
    function addDeadCoin(
        string calldata name,
        string calldata symbol,
        string calldata reason
    ) external onlyOwner nonReentrant returns (uint256) {
        require(bytes(name).length > 0 && bytes(symbol).length > 0, "Name and symbol required");
        require(bytes(reason).length > 0, "Reason required");

        uint256 currentId = nextDeadCoinId;
        deadCoins[currentId] = DeadCoin({
            id: currentId,
            name: name,
            symbol: symbol,
            reason: reason,
            dateDeclaredDead: block.timestamp,
            exists: true
        });

        deadCoinIds.push(currentId);
        nextDeadCoinId++;

        emit DeadCoinAdded(currentId, name, symbol);
        return currentId;
    }

    /// @notice Updates details of an existing dead coin.
    function updateDeadCoin(
        uint256 id,
        string calldata name,
        string calldata symbol,
        string calldata reason
    ) external onlyOwner nonReentrant {
        require(deadCoins[id].exists, "Dead coin does not exist");
        require(bytes(name).length > 0 && bytes(symbol).length > 0, "Name and symbol required");
        require(bytes(reason).length > 0, "Reason required");

        DeadCoin storage coin = deadCoins[id];
        coin.name = name;
        coin.symbol = symbol;
        coin.reason = reason;

        emit DeadCoinUpdated(id, name, symbol, reason);
    }

    /// @notice Removes a dead coin entry from the registry.
    function removeDeadCoin(uint256 id) external onlyOwner nonReentrant {
        require(deadCoins[id].exists, "Dead coin does not exist");

        delete deadCoins[id];

        // Remove ID from the array efficiently
        uint256 length = deadCoinIds.length;
        for (uint256 i = 0; i < length; i++) {
            if (deadCoinIds[i] == id) {
                deadCoinIds[i] = deadCoinIds[length - 1];
                deadCoinIds.pop();
                break;
            }
        }

        emit DeadCoinRemoved(id);
    }

    /// @notice Retrieves dead coin details by ID.
    function getDeadCoin(uint256 id) external view returns (DeadCoin memory) {
        require(deadCoins[id].exists, "Dead coin does not exist");
        return deadCoins[id];
    }

    /// @notice Retrieves all dead coin IDs.
    function getAllDeadCoinIds() external view returns (uint256[] memory) {
        return deadCoinIds;
    }

    /// @notice Returns total number of dead coins.
    function totalDeadCoins() external view returns (uint256) {
        return deadCoinIds.length;
    }
}
