// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ShieldedTransactionSuite
/// @notice Implements MixerTx, ZKShieldedPayment, and RingCT modules
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Basic reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// 1) Simple Mixer Transaction
contract MixerTx is Base, ReentrancyGuard {
    uint public batchSize;
    uint public withdrawWindowStart;
    uint public withdrawWindowEnd;
    mapping(address => bytes32) public commitHash;
    mapping(address => bool)    public hasWithdrawn;

    constructor(uint _batchSize, uint _start, uint _end) {
        batchSize = _batchSize;
        withdrawWindowStart = _start;
        withdrawWindowEnd   = _end;
    }

    // --- Attack: anyone deposits any amount & withdraw anytime
    function depositInsecure() external payable {
        // no amount check
    }
    function withdrawInsecure() external {
        // drains entire pool
        payable(msg.sender).transfer(address(this).balance);
    }

    // --- Defense: fixed-size deposit + commit–reveal + window + cap
    function depositSecure(bytes32 h) external payable {
        require(msg.value == batchSize, "Wrong deposit size");
        require(commitHash[msg.sender] == 0, "Already committed");
        commitHash[msg.sender] = h;
    }
    function revealAndWithdrawSecure(bytes32 nonce) external nonReentrant {
        require(block.timestamp >= withdrawWindowStart &&
                block.timestamp <= withdrawWindowEnd, "Not in window");
        require(commitHash[msg.sender] != 0, "No commit");
        require(!hasWithdrawn[msg.sender], "Already withdrawn");
        require(keccak256(abi.encodePacked(msg.sender, nonce)) ==
                commitHash[msg.sender], "Bad reveal");
        hasWithdrawn[msg.sender] = true;
        payable(msg.sender).transfer(batchSize);
    }

    receive() external payable {}
}

/// 2) zk-SNARK Shielded Payment
contract ZKShieldedPayment is Base, ReentrancyGuard {
    bytes32 public merkleRoot;
    mapping(bytes32 => bool) public nullifierUsed;

    // --- Attack: anyone sets any root & double-spends
    function setRootInsecure(bytes32 root) external {
        merkleRoot = root;
    }
    function payInsecure(bytes32 nullifier) external payable {
        require(!nullifierUsed[nullifier], "Already used");
        nullifierUsed[nullifier] = true;
        // no proof check ⇒ arbitrary pay
    }

    // --- Defense: onlyOwner root + proof verify + nullifier
    function setRootSecure(bytes32 root) external onlyOwner {
        require(root != bytes32(0), "Zero root");
        merkleRoot = root;
    }
    function paySecure(
        bytes calldata proof,
        bytes32 root,
        bytes32 nullifier,
        address payable recipient,
        uint256 amount
    ) external nonReentrant {
        require(root == merkleRoot, "Root mismatch");
        require(!nullifierUsed[nullifier], "Nullifier used");
        require(verifySnark(proof, root, nullifier, recipient, amount),
                "Invalid zk-proof");
        nullifierUsed[nullifier] = true;
        recipient.transfer(amount);
    }

    /// @dev Stub: integrate actual verifier contract
    function verifySnark(
        bytes calldata proof,
        bytes32 root,
        bytes32 nullifier,
        address recipient,
        uint256 amount
    ) public pure returns(bool) {
        // In production, call verifier.verify(...)
        return true;
    }

    receive() external payable {}
}

/// 3) Ring-Signature Transaction (RingCT)
contract RingCT is Base, ReentrancyGuard {
    mapping(bytes32 => bool) public keyImageUsed;
    mapping(address => bool) public validPubKey;

    // --- Attack: anyone forges ring-sig or reuses key-image
    function transactInsecure(
        bytes32 keyImage,
        bytes calldata ringSig,
        address payable[] calldata recipients,
        uint256[] calldata amounts
    ) external payable {
        require(!keyImageUsed[keyImage], "Key image reused");
        keyImageUsed[keyImage] = true;
        // no ring-signature or sum check
        for(uint i = 0; i < recipients.length; i++){
            recipients[i].transfer(amounts[i]);
        }
    }

    // --- Defense: pubkey whitelist + ring-sig verify + key-image
    function registerPubKey(address pk) external onlyOwner {
        validPubKey[pk] = true;
    }
    function transactSecure(
        bytes32 keyImage,
        bytes calldata ringSig,
        address payable[] calldata recipients,
        uint256[] calldata amounts,
        address[] calldata ring
    ) external nonReentrant {
        require(!keyImageUsed[keyImage],                     "Key image reused");
        require(ring.length >= 2 && ring.length <= 16,       "Ring size invalid");
        for(uint i = 0; i < ring.length; i++){
            require(validPubKey[ring[i]], "Invalid ring pubkey");
        }
        require(verifyRingSig(keyImage, ringSig, ring),      "Bad ring signature");
        keyImageUsed[keyImage] = true;
        // Effects done; now transfer
        for(uint i = 0; i < recipients.length; i++){
            recipients[i].transfer(amounts[i]);
        }
    }

    /// @dev Stub: integrate actual ring-signature verifier
    function verifyRingSig(
        bytes32 keyImage,
        bytes calldata ringSig,
        address[] calldata ring
    ) public pure returns(bool) {
        return true;
    }

    receive() external payable {}
}
