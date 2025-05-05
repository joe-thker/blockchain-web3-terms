// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ShieldedAddressSuite
/// @notice Implements SimpleMixer, StealthWallet, and ZKShieldedPool modules
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

/// 1) Simple Mixer
contract SimpleMixer is Base, ReentrancyGuard {
    uint public batchSize;                   // fixed deposit amount
    uint public batchDeadline;               // fixed withdrawal time
    mapping(address => bool) public deposited;
    address[] public participants;

    constructor(uint _batchSize, uint _batchDeadline) {
        batchSize     = _batchSize;
        batchDeadline = _batchDeadline;
    }

    // --- Attack: anyone deposit any amount anytime; withdraw anytime
    function depositInsecure() external payable {
        participants.push(msg.sender);
    }
    function withdrawInsecure() external {
        // naive send all pool to caller
        payable(msg.sender).transfer(address(this).balance);
    }

    // --- Defense: fixed-size & commit–reveal & cap
    mapping(address => bytes32) public commitHash;
    function commitSecure(bytes32 h) external {
        require(msg.value == batchSize, "Wrong amt");
        require(commitHash[msg.sender] == 0, "Already committed");
        commitHash[msg.sender] = h;
        participants.push(msg.sender);
    }
    function revealAndWithdrawSecure(bytes32 nonce) external nonReentrant {
        require(block.timestamp >= batchDeadline, "Too early");
        require(commitHash[msg.sender] != 0, "No commit");
        require(keccak256(abi.encodePacked(msg.sender, nonce)) == commitHash[msg.sender],
                "Bad reveal");
        commitHash[msg.sender] = 0;
        payable(msg.sender).transfer(batchSize);
    }
    // receive funds
    receive() external payable {}
}

/// 2) Stealth Address Wallet
contract StealthWallet is Base {
    // mapping from stealth addr to owner
    mapping(address => address) public ownerOf;
    mapping(address => bool)    public usedNonce;

    // --- Attack: anyone derive address & withdraw funds
    function deriveInsecure(address scanPubKey, uint256 nonce) public pure returns(address){
        return address(uint160(uint(keccak256(abi.encodePacked(scanPubKey, nonce)))));
    }
    function withdrawInsecure(address to) external {
        // no owner check
        payable(to).transfer(address(this).balance);
    }

    // --- Defense: enforce unique nonce + owner sig
    function deriveSecure(address scanPubKey, uint256 nonce, bytes calldata sig) external {
        require(!usedNonce[abi.encodePacked(scanPubKey,nonce).hashCode()], "Nonce reuse");
        // verify owner signature over (scanPubKey, nonce)
        bytes32 msgHash = keccak256(abi.encodePacked(scanPubKey, nonce));
        require(_recover(msgHash, sig) == scanPubKey, "Bad sig");
        address stealth = address(uint160(uint(keccak256(abi.encodePacked(scanPubKey, nonce)))));
        ownerOf[stealth] = scanPubKey;
        usedNonce[abi.encodePacked(scanPubKey,nonce).hashCode()] = true;
    }
    function withdrawSecure() external nonReentrant {
        require(ownerOf[msg.sender] == msg.sender, "Not owner");
        uint bal = address(this).balance;
        payable(msg.sender).transfer(bal);
    }

    function _recover(bytes32 h, bytes memory sig) internal pure returns(address) {
        bytes32 eth = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(sig, (bytes32,bytes32,uint8));
        return ecrecover(eth, v, r, s);
    }
}

/// 3) zk-SNARK Shielded Pool
contract ZKShieldedPool is Base {
    bytes32 public merkleRoot;
    mapping(bytes32 => bool) public nullifierUsed;

    // --- Attack: anyone set bad root or reuse nullifier
    function setRootInsecure(bytes32 root) external {
        merkleRoot = root;
    }

    function withdrawInsecure(bytes32 nullifier) external {
        require(!nullifierUsed[nullifier], "Already");
        nullifierUsed[nullifier] = true;
        payable(msg.sender).transfer(1 ether);
    }

    // --- Defense: onlyOwner + proof verify + nullifier tracking
    function setRootSecure(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    // zk-proof verify stub interface
    function verifyProof(
        bytes calldata proof,
        bytes32 root, bytes32 nullifier, address recipient
    ) public view returns(bool) {
        // assume external verifier integration
        // returns true if proof is valid for (root, nullifier, recipient)
        return true;
    }

    function withdrawSecure(
        bytes calldata proof,
        bytes32 root,
        bytes32 nullifier,
        address recipient
    ) external nonReentrant {
        require(root == merkleRoot, "Root mismatch");
        require(!nullifierUsed[nullifier], "Nullifier used");
        require(verifyProof(proof, root, nullifier, recipient),
                "Invalid zk-proof");
        nullifierUsed[nullifier] = true;
        payable(recipient).transfer(1 ether);
    }

    // deposit to pool
    receive() external payable {}
}
