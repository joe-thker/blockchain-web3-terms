// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SoftwareStackSuite
/// @notice DataAccess, BusinessLogic, and Interface layers with insecure vs. secure patterns

abstract contract Base {
    address public owner;
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
    constructor() { owner = msg.sender; }
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
// 1) Data Access Layer
//////////////////////////////////////////////////////
contract DataAccess is Base {
    uint256[] private _data;

    // --- Attack: no bounds check ⇒ OOB revert or garbage
    function getInsecure(uint256 index) external view returns (uint256) {
        return _data[index];
    }
    // --- Defense: require in‐bounds
    function getSecure(uint256 index) external view returns (uint256) {
        require(index < _data.length, "Index OOB");
        return _data[index];
    }

    // --- Attack: anyone can push data
    function pushInsecure(uint256 x) external {
        _data.push(x);
    }
    // --- Defense: onlyOwner can write
    function pushSecure(uint256 x) external onlyOwner {
        _data.push(x);
    }

    function length() external view returns (uint256) {
        return _data.length;
    }
}

//////////////////////////////////////////////////////
// 2) Business Logic Layer
//////////////////////////////////////////////////////
contract BusinessLogic is Base, ReentrancyGuard {
    mapping(address => uint256) public balances;

    // --- Attack: missing validation ⇒ negative logic or drain
    function transferInsecure(address to, uint256 amt) external {
        // no checks: could underflow or send to zero
        balances[msg.sender] -= amt;
        balances[to] += amt;
    }

    // --- Defense: input + invariant checks + CEI
    function transferSecure(address to, uint256 amt) external nonReentrant {
        require(to != address(0), "Zero addr");
        require(balances[msg.sender] >= amt, "Insufficient");
        // Effects
        balances[msg.sender] -= amt;
        balances[to]        += amt;
        // Interaction: (none)
    }

    // initialize balances (owner only)
    function mint(uint256 amt) external onlyOwner {
        balances[owner] += amt;
    }
}

//////////////////////////////////////////////////////
// 3) Interface Layer (API/Fallback)
//////////////////////////////////////////////////////
contract InterfaceLayer is Base {
    uint256 public constant WINDOW = 1 hours;
    mapping(address => uint256) public lastCall;
    uint256 public counter;

    event Called(address indexed who, uint256 counter);

    // --- Attack: open API, no rate-limit
    function apiInsecure() external {
        counter++;
        emit Called(msg.sender, counter);
    }

    // --- Defense: rate-limit per address + validate input
    function apiSecure(uint256 increment) external {
        require(increment > 0 && increment <= 10, "Bad increment");
        require(block.timestamp >= lastCall[msg.sender] + WINDOW, "Rate limited");
        lastCall[msg.sender] = block.timestamp;
        counter += increment;
        emit Called(msg.sender, counter);
    }

    // --- Attack: open fallback forwards any call ⇒ spoof actions
    fallback() external payable {
        // Dangerous: accepts arbitrary calls
        counter++;
        emit Called(msg.sender, counter);
    }
    // --- Defense: restrict fallback
    receive() external payable {
        // Only accept ETH from owner
        require(msg.sender == owner, "Not owner");
        // do nothing
    }
}
