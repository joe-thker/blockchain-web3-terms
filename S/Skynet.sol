// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// 1) Node Registration & Staking
contract SkynetNodeRegistry is Base, ReentrancyGuard {
    struct Node { address owner; uint256 stake; bool active; }
    mapping(address => Node) public nodes;
    uint256 public minStake = 1 ether;

    // --- Attack: anyone registers without stake, or drains stake
    function registerNodeInsecure() external {
        nodes[msg.sender] = Node(msg.sender, 0, true);
    }
    function unregisterNodeInsecure() external {
        delete nodes[msg.sender];
        payable(msg.sender).transfer(address(this).balance);
    }

    // --- Defense: require stake, only node‐owner can unregister, safe patterns
    function registerNodeSecure() external payable {
        require(msg.value >= minStake, "Insufficient stake");
        Node storage n = nodes[msg.sender];
        require(!n.active, "Already registered");
        n.owner  = msg.sender;
        n.stake  = msg.value;
        n.active = true;
    }
    function unregisterNodeSecure() external nonReentrant {
        Node storage n = nodes[msg.sender];
        require(n.active && n.owner == msg.sender, "Not a node");
        n.active = false;
        uint256 s = n.stake;
        n.stake = 0;
        payable(msg.sender).transfer(s);
    }
}

/// 2) Task Submission & Assignment
contract SkynetTaskManager is Base {
    struct Task { address client; bytes payload; bool assigned; address node; }
    mapping(uint256 => Task) public tasks;
    uint256 public nextTask;
    mapping(address => uint256) public submissions;      // per-client rate

    uint256 public maxPerClient = 10;

    // Insecure: no limits, no validation, arbitrary assignment
    function submitTaskInsecure(bytes calldata payload) external {
        tasks[nextTask++] = Task(msg.sender, payload, true, msg.sender);
    }
    function assignTaskInsecure(uint256 taskId, address node) external {
        Task storage t = tasks[taskId];
        t.assigned = true;
        t.node     = node;
    }

    // Secure: rate‐limit, payload size check, only active nodes
    function submitTaskSecure(bytes calldata payload) external {
        require(submissions[msg.sender] < maxPerClient, "Rate limit");
        require(payload.length > 0 && payload.length <= 1024, "Invalid payload");
        tasks[nextTask++] = Task(msg.sender, payload, false, address(0));
        submissions[msg.sender]++;
    }
    function assignTaskSecure(uint256 taskId, address node, address registry) external {
        SkynetNodeRegistry r = SkynetNodeRegistry(registry);
        Task storage t = tasks[taskId];
        require(!t.assigned, "Already assigned");
        require(r.nodes(node).active, "Node not registered");
        t.assigned = true;
        t.node     = node;
    }
}

/// 3) Reward Distribution & Slashing
contract SkynetRewards is Base, ReentrancyGuard {
    mapping(bytes32 => bool) public paid;  // taskId+node nullifier
    uint256 public rewardPerTask = 0.1 ether;
    mapping(address => uint256) public earned;
    mapping(address => uint256) public slashed;

    // --- Attack: double‐claim reward, reentrancy drains pool
    function claimRewardInsecure(uint256 taskId) external {
        bytes32 key = keccak256(abi.encodePacked(taskId, msg.sender));
        require(!paid[key], "Already paid");
        paid[key] = true;
        payable(msg.sender).transfer(rewardPerTask);
    }

    // --- Defense: nullifier, CEI, per‐node cap
    function claimRewardSecure(uint256 taskId) external nonReentrant {
        bytes32 key = keccak256(abi.encodePacked(taskId, msg.sender));
        require(!paid[key], "Already paid");
        paid[key] = true;
        earned[msg.sender] += rewardPerTask;
        require(earned[msg.sender] <= 10 ether, "Per-node cap");
        (bool ok,) = payable(msg.sender).call{ value: rewardPerTask }("");
        require(ok, "Payout failed");
    }

    // Slash misbehaving node
    function slashNode(address node, uint256 amount) external onlyOwner {
        slashed[node] += amount;
    }

    receive() external payable {}
}
