// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ShillingSuite
/// @notice Implements PumpBot, InfluencerRewards, and AirdropDistributor modules
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
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

/// 1) Pump-and-Dump Bot
contract PumpBot is Base, ReentrancyGuard {
    IERC20 public token;
    uint256 public maxBuyPerWindow;
    uint256 public windowSize;
    mapping(address => uint256) public boughtInWindow;
    mapping(address => uint256) public windowStart;

    constructor(address _token, uint256 _maxBuy, uint256 _window) {
        token = IERC20(_token);
        maxBuyPerWindow = _maxBuy;
        windowSize = _window;
    }

    // --- Attack: no limits, can front-run and wash-trade
    function buyInsecure(uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        // immediate sell back (dump)
        token.transfer(msg.sender, amount);
    }

    // --- Defense: per-window limit + CEI + reentrancy guard
    function buySecure(uint256 amount) external nonReentrant {
        // reset window if needed
        if (block.timestamp > windowStart[msg.sender] + windowSize) {
            windowStart[msg.sender] = block.timestamp;
            boughtInWindow[msg.sender] = 0;
        }
        require(boughtInWindow[msg.sender] + amount <= maxBuyPerWindow, "Buy limit exceeded");
        // Effects
        boughtInWindow[msg.sender] += amount;
        // Interaction
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }
}

/// Minimal ERC20 interface
interface IERC20 {
    function transfer(address to, uint256 amt) external returns (bool);
    function transferFrom(address from, address to, uint256 amt) external returns (bool);
}

/// 2) Influencer Reward Program
contract InfluencerRewards is Base {
    IERC20 public token;
    uint256 public minHold;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public claimed;
    uint256 public capPerInfluencer;

    constructor(address _token, uint256 _minHold, uint256 _cap) {
        token = IERC20(_token);
        minHold = _minHold;
        capPerInfluencer = _cap;
    }

    // --- Attack: anyone registers and claims unlimited tokens
    function registerInsecure(address influencer) external {
        whitelisted[influencer] = true;
    }
    function claimInsecure() external {
        require(whitelisted[msg.sender], "Not registered");
        uint256 amount = capPerInfluencer;
        claimed[msg.sender] += amount;
        token.transfer(msg.sender, amount);
    }

    // --- Defense: require minimum holding + merkle proof + caps + owner dispense
    function claimSecure(bytes32[] calldata proof, uint256 amount) external nonReentrant {
        require(claimed[msg.sender] + amount <= capPerInfluencer, "Cap exceeded");
        require(IERC20(token).balanceOf(msg.sender) >= minHold, "Insufficient holding");
        // verify via Merkle proof (off-chain merkleRoot set by owner)
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(_verifyProof(leaf, proof), "Invalid proof");
        claimed[msg.sender] += amount;
        token.transfer(msg.sender, amount);
    }

    bytes32 public merkleRoot;
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function _verifyProof(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        bytes32 hash = leaf;
        for (uint i = 0; i < proof.length; i++) {
            bytes32 p = proof[i];
            hash = hash < p 
                ? keccak256(abi.encodePacked(hash, p)) 
                : keccak256(abi.encodePacked(p, hash));
        }
        return hash == merkleRoot;
    }
}

/// 3) Airdrop Spam Campaign
contract AirdropDistributor is Base {
    IERC20 public token;
    uint256 public minHoldThreshold;
    uint256 public batchLimit;
    mapping(address => bool) public hasClaimed;

    constructor(address _token, uint256 _minHold, uint256 _batchLimit) {
        token = IERC20(_token);
        minHoldThreshold = _minHold;
        batchLimit = _batchLimit;
    }

    // --- Attack: spam claims, no checks, massive loops
    function airdropInsecure(address[] calldata recipients, uint256 amount) external {
        for (uint i = 0; i < recipients.length; i++) {
            token.transfer(recipients[i], amount);
        }
    }

    // --- Defense: batch size limit + holding threshold + dedupe
    function airdropSecure(address[] calldata recipients, uint256 amount) external onlyOwner {
        require(recipients.length <= batchLimit, "Batch too large");
        for (uint i = 0; i < recipients.length; i++) {
            address r = recipients[i];
            require(!hasClaimed[r], "Already claimed");
            require(IERC20(token).balanceOf(r) >= minHoldThreshold, "Below threshold");
            hasClaimed[r] = true;
            token.transfer(r, amount);
        }
    }
}
