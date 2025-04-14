// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NickSzaboDigitalWill {
    address public owner;
    uint256 public releaseTime;
    bool public executed;

    struct Beneficiary {
        address account;
        uint256 shareBasisPoints; // Basis points (out of 10,000)
    }
    Beneficiary[] public beneficiaries;

    event WillExecuted(uint256 totalReleased);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 _releaseTime) {
        require(_releaseTime > block.timestamp, "Release time must be in the future");
        owner = msg.sender;
        releaseTime = _releaseTime;
    }

    /// @notice Set beneficiaries and their shares. Total shares must equal 10,000.
    function setBeneficiaries(Beneficiary[] calldata _beneficiaries) external onlyOwner {
        delete beneficiaries;
        uint256 totalShares;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            beneficiaries.push(_beneficiaries[i]);
            totalShares += _beneficiaries[i].shareBasisPoints;
        }
        require(totalShares == 10000, "Total shares must equal 10,000");
    }

    /// @notice Deposit funds into the will contract.
    receive() external payable {}

    /// @notice Execute the will and distribute funds to beneficiaries.
    function executeWill() external onlyOwner {
        require(block.timestamp >= releaseTime, "Will not released yet");
        require(!executed, "Will already executed");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to distribute");

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            uint256 amount = (balance * beneficiaries[i].shareBasisPoints) / 10000;
            payable(beneficiaries[i].account).transfer(amount);
        }
        executed = true;
        emit WillExecuted(balance);
    }
}
