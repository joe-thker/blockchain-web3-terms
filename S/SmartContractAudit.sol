// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title AuditPatternsSuite
/// @notice Demonstrates insecure vs. secure patterns for Reentrancy, Overflow, and Front-Running
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _lock;
    modifier nonReentrant() {
        require(!_lock, "Reentrant");
        _lock = true;
        _;
        _lock = false;
    }
}

//////////////////////////////////////////////////////
// 1) Reentrancy Vulnerability
//////////////////////////////////////////////////////
contract ReentrancyExample is Base, ReentrancyGuard {
    mapping(address => uint256) public balances;

    // --- Attack: withdraw without CEI, vulnerable to reentrancy
    function depositInsecure() external payable {
        balances[msg.sender] += msg.value;
    }
    function withdrawInsecure(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient");
        // external call before state update
        (bool ok, ) = msg.sender.call{ value: amount }("");
        require(ok, "Call failed");
        balances[msg.sender] -= amount;
    }

    // --- Defense: Checks-Effects-Interactions + nonReentrant
    function depositSecure() external payable {
        balances[msg.sender] += msg.value;
    }
    function withdrawSecure(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient");
        // Effects
        balances[msg.sender] -= amount;
        // Interaction
        (bool ok, ) = msg.sender.call{ value: amount, gas: 2300 }("");
        require(ok, "Transfer failed");
    }
}

//////////////////////////////////////////////////////
// 2) Integer Overflow/Underflow
//////////////////////////////////////////////////////
contract OverflowExample is Base {
    uint256 public counter;

    // --- Attack: unchecked increment can wrap around
    function incInsecure(uint256 amount) external {
        unchecked {
            counter += amount;
        }
    }

    // --- Defense: rely on Solidity >=0.8 overflow checks
    function incSecure(uint256 amount) external {
        counter += amount;
    }
}

//////////////////////////////////////////////////////
// 3) Front-Running & Transaction Ordering
//////////////////////////////////////////////////////
contract FrontRunningExample is Base {
    mapping(address => uint256) public orders;
    uint112 public reserveA;
    uint112 public reserveB;

    // naïve spot swap; front-runnable
    function swapInsecure(uint256 amountAIn) external {
        // no slippage or minReceived check
        uint256 amountBOut = uint256(reserveB) * amountAIn / reserveA;
        reserveA += uint112(amountAIn);
        reserveB -= uint112(amountBOut);
        // send without bounds
        payable(msg.sender).transfer(amountBOut);
    }

    // Commit–reveal to prevent frontrunning
    mapping(address => bytes32) public commitHash;
    uint256 public revealDeadline;

    function commitSwap(bytes32 h, uint256 deadline) external payable {
        require(msg.value == 0, "No ETH");
        // record minimum out and deadline
        commitHash[msg.sender] = h;
        revealDeadline = deadline;
    }

    // --- Attack: reveal immediately in same block
    function revealInsecure(uint256 amountAIn, uint256 minBOut) external {
        require(block.timestamp <= revealDeadline, "Deadline passed");
        // no proof of prior commit; vulnerable
        uint256 amountBOut = uint256(reserveB) * amountAIn / reserveA;
        require(amountBOut >= minBOut, "Slipped");
        reserveA += uint112(amountAIn);
        reserveB -= uint112(amountBOut);
        payable(msg.sender).transfer(amountBOut);
    }

    // --- Defense: enforce commit hash, slippage bound
    function revealSecure(
        uint256 amountAIn,
        uint256 minBOut,
        uint256 nonce
    ) external {
        require(block.timestamp <= revealDeadline, "Deadline passed");
        // verify commit was made over (amountAIn, minBOut, nonce)
        bytes32 h = keccak256(abi.encodePacked(amountAIn, minBOut, nonce));
        require(commitHash[msg.sender] == h, "Bad reveal");
        // CEI
        uint256 amountInWithFee = amountAIn * 997 / 1000;
        uint256 numerator   = amountInWithFee * reserveB;
        uint256 denominator = uint256(reserveA) * 1000 + amountInWithFee;
        uint256 amountBOut  = numerator / denominator;
        require(amountBOut >= minBOut, "Slippage too high");
        // Effects
        reserveA += uint112(amountAIn);
        reserveB -= uint112(amountBOut);
        // Interaction
        payable(msg.sender).transfer(amountBOut);
        delete commitHash[msg.sender];
    }

    // helper to fund and set reserves
    function initLiquidity(uint112 a, uint112 b) external onlyOwner {
        reserveA = a;
        reserveB = b;
    }

    receive() external payable {}
}
