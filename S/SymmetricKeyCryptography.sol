// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SymmetricKeyModule - Simulated Attack & Defense for Symmetric Key Cryptography in Solidity

// ==============================
// 🔐 Symmetric Commit-Reveal Contract
// ==============================
contract SymmetricLockbox {
    struct Lock {
        address owner;
        bytes32 commitment;
        bool claimed;
        uint256 revealBlock;
    }

    mapping(bytes32 => Lock) public locks;
    uint256 public constant REVEAL_DELAY = 2;

    event Locked(bytes32 indexed id, address indexed user);
    event Revealed(bytes32 indexed id, string key, address indexed user);

    function commit(bytes32 lockId, bytes32 commitment) external {
        require(locks[lockId].owner == address(0), "Already committed");
        locks[lockId] = Lock({
            owner: msg.sender,
            commitment: commitment,
            claimed: false,
            revealBlock: block.number
        });
        emit Locked(lockId, msg.sender);
    }

    function reveal(bytes32 lockId, string memory key) external {
        Lock storage l = locks[lockId];
        require(msg.sender == l.owner, "Not owner");
        require(!l.claimed, "Already claimed");
        require(block.number > l.revealBlock + REVEAL_DELAY, "Reveal too soon");

        bytes32 derived = keccak256(abi.encodePacked(key, msg.sender));
        require(derived == l.commitment, "Invalid key");

        l.claimed = true;
        emit Revealed(lockId, key, msg.sender);
    }
}

// ==============================
// 🔓 Attack: Reusing/Replaying Symmetric Keys
// ==============================
contract SymmetricAttackCommit {
    function forgeReveal(bytes32 lockId, address user, string memory knownKey) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(knownKey, user)); // Try to guess key
    }

    function mimicCommit(string memory key, address user) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(key, user)); // Match commitment structure
    }
}

// ==============================
// 🧪 Key Derivation Simulator
// ==============================
contract KeyManager {
    function deriveKey(string memory secret, address user, uint256 salt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(secret, user, salt));
    }

    function verifyKey(bytes32 provided, string memory secret, address user, uint256 salt) public pure returns (bool) {
        return provided == keccak256(abi.encodePacked(secret, user, salt));
    }
}
