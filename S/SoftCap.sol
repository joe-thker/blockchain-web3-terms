// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Base {
    address public owner;
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
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

/// @title SoftCapSaleSuite
/// @notice Implements BasicSale, CappedSale, and TieredSale modules
contract SoftCapSaleSuite is Base, ReentrancyGuard {
    /// COMMON STRUCTS & STATE
    struct Phase { uint256 start; uint256 end; uint256 softCap; uint256 raised; uint256 perAddressCap; }
    mapping(uint8 => Phase) public phases;
    mapping(uint8 => mapping(address=>uint256)) public contributed;
    mapping(address => uint256) public refunds;
    uint256 public overallDeadline;

    /// EVENTS
    event Contributed(address indexed who, uint8 phase, uint256 amount);
    event OwnerWithdrawn(uint256 amount);
    event RefundClaimed(address indexed who, uint256 amount);

    constructor(uint256 _overallDeadline) {
        overallDeadline = _overallDeadline;
    }

    /// ------------------------------------------------------------------------
    /// 1) Basic Soft‐Cap Sale
    /// ------------------------------------------------------------------------
    // Insecure: owner drains funds anytime & no refunds
    function basicDepositInsecure() external payable {
        // just collect
    }
    function basicOwnerWithdrawInsecure() external onlyOwner {
        // no checks
        payable(owner).transfer(address(this).balance);
        emit OwnerWithdrawn(address(this).balance);
    }

    // Secure: allow owner withdraw only if softCap met before deadline, else enable refunds
    function basicSetup(uint256 softCap, uint256 deadline) external onlyOwner {
        phases[0] = Phase(0, deadline, softCap, 0, type(uint256).max);
    }
    function basicDepositSecure() external payable {
        Phase storage p = phases[0];
        require(block.timestamp <= p.end, "Sale ended");
        p.raised += msg.value;
        emit Contributed(msg.sender, 0, msg.value);
    }
    function basicOwnerWithdrawSecure() external onlyOwner {
        Phase storage p = phases[0];
        require(block.timestamp <= p.end, "After deadline");
        require(p.raised >= p.softCap, "Soft cap not reached");
        payable(owner).transfer(p.raised);
        emit OwnerWithdrawn(p.raised);
    }
    function basicClaimRefundSecure() external nonReentrant {
        Phase storage p = phases[0];
        require(block.timestamp > p.end, "Sale not ended");
        require(p.raised < p.softCap, "Soft cap met");
        uint256 amt = refunds[msg.sender];
        if (amt == 0) amt = contributed[0][msg.sender];
        require(amt > 0, "No refund");
        refunds[msg.sender] = 0;
        payable(msg.sender).transfer(amt);
        emit RefundClaimed(msg.sender, amt);
    }

    /// ------------------------------------------------------------------------
    /// 2) Per‐Address Contribution Cap Sale
    /// ------------------------------------------------------------------------
    // Insecure: no per‐address cap, unlimited contribution
    function cappedDepositInsecure(uint8 phaseId) external payable {
        // just collect
        phases[phaseId].raised += msg.value;
    }

    // Secure: enforce perAddressCap & track per‐address
    function cappedSetup(uint8 phaseId, uint256 start, uint256 end, uint256 softCap, uint256 perAddressCap) external onlyOwner {
        phases[phaseId] = Phase(start, end, softCap, 0, perAddressCap);
    }
    function cappedDepositSecure(uint8 phaseId) external payable {
        Phase storage p = phases[phaseId];
        require(block.timestamp >= p.start && block.timestamp <= p.end, "Not in phase");
        require(contributed[phaseId][msg.sender] + msg.value <= p.perAddressCap, "Per-address cap");
        contributed[phaseId][msg.sender] += msg.value;
        p.raised += msg.value;
        emit Contributed(msg.sender, phaseId, msg.value);
    }
    function cappedOwnerWithdrawSecure(uint8 phaseId) external onlyOwner {
        Phase storage p = phases[phaseId];
        require(block.timestamp <= p.end, "Phase ended");
        require(p.raised >= p.softCap, "Soft cap not reached");
        payable(owner).transfer(p.raised);
        emit OwnerWithdrawn(p.raised);
    }

    /// ------------------------------------------------------------------------
    /// 3) Tiered Soft‐Cap with Time Gates
    /// ------------------------------------------------------------------------
    // Insecure: allow contributions outside time gates & ignore phase caps
    function tieredDepositInsecure(uint8 phaseId) external payable {
        phases[phaseId].raised += msg.value;
    }

    // Secure: enforce per‐phase start/end & softCap
    function tieredSetup(uint8 phaseId, uint256 start, uint256 end, uint256 softCap, uint256 perAddressCap) external onlyOwner {
        phases[phaseId] = Phase(start, end, softCap, 0, perAddressCap);
    }
    function tieredDepositSecure(uint8 phaseId) external payable {
        Phase storage p = phases[phaseId];
        require(block.timestamp >= p.start && block.timestamp <= p.end, "Outside phase window");
        require(contributed[phaseId][msg.sender] + msg.value <= p.perAddressCap, "Per-address cap");
        p.raised += msg.value;
        contributed[phaseId][msg.sender] += msg.value;
        emit Contributed(msg.sender, phaseId, msg.value);
    }
    function tieredOwnerWithdrawSecure(uint8 phaseId) external onlyOwner {
        Phase storage p = phases[phaseId];
        require(block.timestamp <= p.end, "Phase ended");
        require(p.raised >= p.softCap, "Soft cap not reached");
        payable(owner).transfer(p.raised);
        emit OwnerWithdrawn(p.raised);
    }
}
