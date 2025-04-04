// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MilestoneEscrow {
    address public depositor;
    address public beneficiary;
    address public arbiter;

    struct Milestone {
        uint256 amount;
        bool isReleased;
    }

    Milestone[] public milestones;
    uint256 public totalDeposited;

    event MilestoneAdded(uint256 indexed id, uint256 amount);
    event MilestoneReleased(uint256 indexed id, uint256 amount);
    event Refunded(uint256 amount);

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter");
        _;
    }

    modifier onlyDepositor() {
        require(msg.sender == depositor, "Only depositor");
        _;
    }

    constructor(address _beneficiary, address _arbiter) payable {
        require(msg.value > 0, "Must send ETH");
        depositor = msg.sender;
        beneficiary = _beneficiary;
        arbiter = _arbiter;
        totalDeposited = msg.value;
    }

    function addMilestones(uint256[] calldata amounts) external onlyDepositor {
        uint256 sum = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            milestones.push(Milestone({amount: amounts[i], isReleased: false}));
            sum += amounts[i];
            emit MilestoneAdded(i, amounts[i]);
        }
        require(sum == totalDeposited, "Amounts must equal deposit");
    }

    function releaseMilestone(uint256 index) external onlyArbiter {
        require(index < milestones.length, "Invalid milestone");
        Milestone storage m = milestones[index];
        require(!m.isReleased, "Already released");
        m.isReleased = true;

        (bool sent, ) = beneficiary.call{value: m.amount}("");
        require(sent, "Transfer failed");
        emit MilestoneReleased(index, m.amount);
    }

    function refundRemaining() external onlyDepositor {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to refund");
        (bool sent, ) = depositor.call{value: balance}("");
        require(sent, "Refund failed");
        emit Refunded(balance);
    }
}
