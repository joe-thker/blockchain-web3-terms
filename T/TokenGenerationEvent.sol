// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TGE_Module - Token Generation Event (TGE) Secure Framework

// ==============================
// 🪙 ERC20 Token for TGE
// ==============================
contract TGEToken {
    string public name = "LaunchToken";
    string public symbol = "LAUNCH";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public immutable cap;

    address public minter;
    mapping(address => uint256) public balances;

    constructor(uint256 _cap) {
        cap = _cap;
        minter = msg.sender;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Not minter");
        _;
    }

    function mint(address to, uint256 amt) external onlyMinter {
        require(totalSupply + amt <= cap, "Cap exceeded");
        totalSupply += amt;
        balances[to] += amt;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Insufficient");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

// ==============================
// 🔐 TGE Claim Contract (Merkle-Protected)
// ==============================
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TGEClaim {
    TGEToken public token;
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;
    bool public active;

    event Claimed(address indexed user, uint256 amount);

    constructor(address _token, bytes32 _root) {
        token = TGEToken(_token);
        merkleRoot = _root;
        active = true;
    }

    function claim(uint256 amount, bytes32[] calldata proof) external {
        require(active, "Claim disabled");
        require(!claimed[msg.sender], "Already claimed");

        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(proof, merkleRoot, node), "Invalid proof");

        claimed[msg.sender] = true;
        token.mint(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    function disableClaim() external {
        require(msg.sender == address(token), "Only token admin");
        active = false;
    }
}

// ==============================
// 🔐 Locking Vault for Team & Investors
// ==============================
contract TGELocker {
    TGEToken public token;
    uint256 public unlockTime;
    mapping(address => uint256) public locked;

    constructor(address _token, uint256 delaySeconds) {
        token = TGEToken(_token);
        unlockTime = block.timestamp + delaySeconds;
    }

    function lock(address user, uint256 amt) external {
        require(msg.sender == address(token), "Only token admin");
        token.mint(address(this), amt);
        locked[user] += amt;
    }

    function unlock() external {
        require(block.timestamp >= unlockTime, "Locked");
        uint256 amt = locked[msg.sender];
        require(amt > 0, "None");

        locked[msg.sender] = 0;
        token.transfer(msg.sender, amt);
    }
}

// ==============================
// 🔓 TGE Attacker (Double Claim Attempt)
// ==============================
interface ITGEClaim {
    function claim(uint256, bytes32[] calldata) external;
}

contract TGEAttacker {
    function tryDoubleClaim(ITGEClaim claimContract, uint256 amount, bytes32[] calldata proof) external {
        claimContract.claim(amount, proof);
        claimContract.claim(amount, proof); // second claim attempt
    }
}
