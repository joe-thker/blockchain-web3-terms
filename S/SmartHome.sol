// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SmartHomeSuite
/// @notice Access Control, Device Scheduling, and Sensor Logging patterns
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() {
        owner = msg.sender;
    }
}

/// Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

//////////////////////////////////////////////////////
// 1) Access Control & Authorization
//////////////////////////////////////////////////////
contract AccessControl is Base {
    mapping(address => bool) public authorized;
    mapping(address => uint256) public nonces;

    event DeviceToggled(address indexed user, uint256 nonce, bool state);

    // --- Attack: no auth, no replay protection
    function toggleInsecure(bool state) external {
        // anyone can call, repeating toggles
        emit DeviceToggled(msg.sender, nonces[msg.sender]++, state);
    }

    // --- Defense: onlyAuthorized + nonce check
    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Not authorized");
        _;
    }
    function toggleSecure(bool state, uint256 nonce) external onlyAuthorized {
        require(nonce == nonces[msg.sender], "Bad nonce");
        nonces[msg.sender]++;
        emit DeviceToggled(msg.sender, nonce, state);
    }

    function setAuthorized(address user, bool ok) external onlyOwner {
        authorized[user] = ok;
    }
}

//////////////////////////////////////////////////////
// 2) Automated Device Control (Scheduling)
//////////////////////////////////////////////////////
contract Scheduler is Base, ReentrancyGuard {
    struct Task { address scheduler; uint256 execTime; bytes data; bool exists; }
    mapping(uint256 => Task) public tasks;
    uint256 public nextTask;

    event TaskCreated(uint256 id, address by, uint256 execTime);
    event TaskCancelled(uint256 id);

    // --- Attack: allow past scheduling, anyone cancel
    function scheduleInsecure(uint256 execTime, bytes calldata data) external {
        tasks[nextTask] = Task(msg.sender, execTime, data, true);
        emit TaskCreated(nextTask, msg.sender, execTime);
        nextTask++;
    }
    function cancelInsecure(uint256 id) external {
        delete tasks[id];
        emit TaskCancelled(id);
    }

    // --- Defense: future‐only + only owner of task + nonReentrant
    function scheduleSecure(uint256 execTime, bytes calldata data) external {
        require(execTime > block.timestamp, "Exec time past");
        tasks[nextTask] = Task(msg.sender, execTime, data, true);
        emit TaskCreated(nextTask, msg.sender, execTime);
        nextTask++;
    }
    function cancelSecure(uint256 id) external nonReentrant {
        Task storage t = tasks[id];
        require(t.exists, "No task");
        require(t.scheduler == msg.sender, "Not scheduler");
        delete tasks[id];
        emit TaskCancelled(id);
    }

    // function to execute due tasks would be off-chain or via keeper
}

//////////////////////////////////////////////////////
// 3) Sensor Data Logging & Privacy
//////////////////////////////////////////////////////
contract SensorLogger is Base {
    // store only hash of encrypted data
    mapping(uint256 => bytes32) public logHash;
    mapping(address => uint256) public submissions;
    uint256 public constant WINDOW = 1 hours;
    mapping(address => uint256) public lastSubmission;

    event DataLogged(address indexed by, uint256 indexed idx, bytes32 hash);

    // --- Attack: plaintext logs, uncontrolled spam
    function logInsecure(uint256 idx, string calldata data) external {
        // stores raw data on-chain
        // gas and privacy leak
        // solhint-disable-next-line
        logHash[idx] = keccak256(abi.encodePacked(data));
        emit DataLogged(msg.sender, idx, logHash[idx]);
    }

    // --- Defense: onlyAuthorized + rate‐limit + require encrypted hash
    mapping(address => bool) public authorized;
    function setAuthorized(address user, bool ok) external onlyOwner {
        authorized[user] = ok;
    }
    function logSecure(uint256 idx, bytes32 encryptedHash) external {
        require(authorized[msg.sender], "Not authorized");
        require(block.timestamp >= lastSubmission[msg.sender] + WINDOW, "Rate limited");
        logHash[idx] = encryptedHash;
        lastSubmission[msg.sender] = block.timestamp;
        emit DataLogged(msg.sender, idx, encryptedHash);
    }
}
