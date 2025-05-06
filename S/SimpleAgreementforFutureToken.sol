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

/// 1) Pre-Sale Deposit Agreement
contract SAFTDeposits is Base, ReentrancyGuard {
    mapping(address => uint256) public deposited;
    uint256 public capPerAddress;
    uint256 public totalDeposits;
    uint256 public refundDeadline;   // timestamp after which refund allowed

    constructor(uint256 _cap, uint256 _refundDeadline) {
        capPerAddress = _cap;
        refundDeadline = _refundDeadline;
    }

    // --- Attack: unlimited deposits, no refunds, no reentrancy guard
    function depositInsecure() external payable {
        deposited[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    // --- Defense: cap per address + nonReentrant + refund window
    function depositSecure() external payable nonReentrant {
        require(deposited[msg.sender] + msg.value <= capPerAddress, "Caps exceeded");
        deposited[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    // buyer refunds if tokens never delivered after deadline
    function refundSecure() external nonReentrant {
        require(block.timestamp >= refundDeadline, "Too early for refund");
        uint256 amt = deposited[msg.sender];
        require(amt > 0, "Nothing to refund");
        deposited[msg.sender] = 0;
        totalDeposits -= amt;
        payable(msg.sender).transfer(amt);
    }
}

/// 2) Token Allocation Vesting SAFT
contract SAFTVesting is Base, ReentrancyGuard {
    struct Grant { uint256 total; uint256 released; uint256 start; uint256 cliff; uint256 duration; }
    mapping(address => Grant) public grants;

    // --- Attack: claim full immediately, no schedule checks
    function claimVestInsecure() external {
        Grant storage g = grants[msg.sender];
        require(g.total > 0, "No grant");
        uint256 amt = g.total;
        g.total = 0;
        payable(msg.sender).transfer(amt);
    }

    // --- Defense: enforce cliff + linear vesting + nonReentrant + CEI
    function claimVestSecure() external nonReentrant {
        Grant storage g = grants[msg.sender];
        require(g.total > 0, "No grant");
        uint256 t = block.timestamp;
        require(t >= g.start + g.cliff, "Cliff not reached");
        uint256 elapsed = t - g.start;
        uint256 vested = elapsed >= g.duration
            ? g.total
            : (g.total * elapsed) / g.duration;
        uint256 releasable = vested - g.released;
        require(releasable > 0, "Nothing to release");
        g.released += releasable;
        payable(msg.sender).transfer(releasable);
    }

    // owner sets up vesting grant
    function grantTokens(
        address to,
        uint256 amount,
        uint256 start,
        uint256 cliff,
        uint256 duration
    ) external onlyOwner {
        grants[to] = Grant(amount, 0, start, cliff, duration);
    }

    receive() external payable {}
}

/// 3) Discounted Purchase Option SAFT
contract SAFTOption is Base, ReentrancyGuard {
    uint256 public priceWei;          // discounted price per token
    uint256 public exerciseStart;
    uint256 public exerciseEnd;
    uint256 public capPerAddress;
    uint256 public totalCap;
    mapping(address => uint256) public exercised;
    uint256 public totalExercised;

    constructor(
        uint256 _price,
        uint256 _start,
        uint256 _end,
        uint256 _capPer,
        uint256 _totalCap
    ) {
        priceWei       = _price;
        exerciseStart  = _start;
        exerciseEnd    = _end;
        capPerAddress  = _capPer;
        totalCap       = _totalCap;
    }

    // --- Attack: no time window, no caps, no reentrancy guard
    function exerciseInsecure(uint256 amount) external payable {
        require(msg.value == amount * priceWei, "Wrong ETH");
        // no caps, unlimited exercise
        payable(msg.sender).transfer(amount * 0);  // stub token transfer
    }

    // --- Defense: enforce window, caps, nonReentrant + CEI
    function exerciseSecure(uint256 amount) external payable nonReentrant {
        require(block.timestamp >= exerciseStart && block.timestamp <= exerciseEnd, "Not in window");
        require(exercised[msg.sender] + amount <= capPerAddress, "Address cap exceeded");
        require(totalExercised + amount <= totalCap, "Total cap exceeded");
        require(msg.value == amount * priceWei, "Wrong ETH");
        exercised[msg.sender] += amount;
        totalExercised += amount;
        // proceed with token transfer stub
        payable(msg.sender).transfer(0);
    }

    // owner can withdraw ETH
    function withdrawETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}
