// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SidechainSuite
/// @notice Implements PegBridge, ValidatorSet, and StateSync modules
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// 1) Peg-In/Peg-Out Bridge
contract PegBridge is Base, ReentrancyGuard {
    bytes32 public mainChainRoot;                // trusted header root
    mapping(bytes32 => bool) public spent;       // withdrawal proofs used

    event Deposit(address indexed user, uint256 amount, uint256 sidechainTokenId);
    event Withdraw(address indexed user, uint256 amount, bytes32 proofId);

    // --- Attack: anyone can withdraw without proof or replay checks
    function withdrawInsecure(uint256 amount, bytes32 proofId) external nonReentrant {
        // no proof verification, no nonce tracking
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount, proofId);
    }

    // --- Defense: require Merkle-proof against mainChainRoot + no replay
    function withdrawSecure(
        uint256 amount,
        bytes32 proofId,
        bytes32[] calldata proof,
        bytes32 leaf
    ) external nonReentrant {
        require(!spent[proofId], "Already withdrawn");
        // verify leaf encodes (msg.sender, amount, proofId)
        bytes32 root = _computeRoot(leaf, proof);
        require(root == mainChainRoot, "Bad proof");
        spent[proofId] = true;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount, proofId);
    }

    function depositInsecure() external payable {
        // simply mint sidechain tokens without event
        emit Deposit(msg.sender, msg.value, 0);
    }
    function _computeRoot(bytes32 h, bytes32[] memory proof) internal pure returns (bytes32) {
        bytes32 hash = h;
        for (uint i = 0; i < proof.length; i++) {
            bytes32 p = proof[i];
            hash = hash < p
                ? keccak256(abi.encodePacked(hash, p))
                : keccak256(abi.encodePacked(p, hash));
        }
        return hash;
    }

    function setMainChainRoot(bytes32 root) external onlyOwner {
        mainChainRoot = root;
    }

    receive() external payable {}
}

/// 2) Validator Set Management
contract ValidatorSet is Base {
    mapping(address => bool) public isValidator;
    uint256 public epoch;

    event ValidatorAdded(address indexed v, uint256 epoch);
    event ValidatorRemoved(address indexed v, uint256 epoch);

    // --- Attack: anyone can add/remove validators
    function addValidatorInsecure(address v) external {
        isValidator[v] = true;
        emit ValidatorAdded(v, epoch);
    }
    function removeValidatorInsecure(address v) external {
        delete isValidator[v];
        emit ValidatorRemoved(v, epoch);
    }

    // --- Defense: onlyOwner + epoch bump
    function addValidatorSecure(address v) external onlyOwner {
        require(!isValidator[v], "Already validator");
        isValidator[v] = true;
        epoch++;
        emit ValidatorAdded(v, epoch);
    }
    function removeValidatorSecure(address v) external onlyOwner {
        require(isValidator[v], "Not validator");
        delete isValidator[v];
        epoch++;
        emit ValidatorRemoved(v, epoch);
    }
}

/// 3) State Sync / Cross-Chain Messaging
contract StateSync is Base, ReentrancyGuard {
    bytes32 public latestStateRoot;
    mapping(uint256 => bool) public processed;  // message nonces

    event StateSynced(uint256 indexed nonce, bytes32 newRoot);

    // --- Attack: anyone posts any root, replays old nonces
    function syncInsecure(uint256 nonce, bytes32 newRoot) external {
        latestStateRoot = newRoot;
        emit StateSynced(nonce, newRoot);
    }

    // --- Defense: only validators via owner signature + nonce tracking
    function syncSecure(
        uint256 nonce,
        bytes32 newRoot,
        bytes calldata signature
    ) external nonReentrant {
        require(!processed[nonce], "Already processed");
        // require signature by owner (could be multisig)
        bytes32 msgHash = keccak256(abi.encodePacked(nonce, newRoot));
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        address signer = _recover(ethHash, signature);
        require(signer == owner, "Bad signature");
        processed[nonce] = true;
        latestStateRoot = newRoot;
        emit StateSynced(nonce, newRoot);
    }

    function _recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "Invalid sig");
        bytes32 r; bytes32 s; uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return ecrecover(hash, v, r, s);
    }
}
