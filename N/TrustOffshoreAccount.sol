// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title TrustOffshoreAccount
 * @notice Owner deposits ETH for a beneficiary. The beneficiary can withdraw
 *         only after `releaseTime`. Owner may update parameters before release.
 */
contract TrustOffshoreAccount is Ownable, Pausable {
    address public beneficiary;
    uint256 public releaseTime;
    uint256 public balance;

    event Deposited(uint256 amount);
    event BeneficiaryChanged(address indexed oldBeneficiary, address indexed newBeneficiary);
    event ReleaseTimeChanged(uint256 oldReleaseTime, uint256 newReleaseTime);
    event Withdrawn(address indexed beneficiary, uint256 amount);

    constructor(address _beneficiary, uint256 _releaseTime) Ownable(msg.sender) {
        require(_beneficiary != address(0), "Zero beneficiary");
        require(_releaseTime > block.timestamp, "Release in future");
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    receive() external payable {
        balance += msg.value;
        emit Deposited(msg.value);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setBeneficiary(address newBeneficiary) external onlyOwner {
        require(newBeneficiary != address(0), "Zero address");
        emit BeneficiaryChanged(beneficiary, newBeneficiary);
        beneficiary = newBeneficiary;
    }

    function setReleaseTime(uint256 newTime) external onlyOwner {
        require(newTime > block.timestamp, "Must be future");
        emit ReleaseTimeChanged(releaseTime, newTime);
        releaseTime = newTime;
    }

    function withdraw() external whenNotPaused {
        require(msg.sender == beneficiary, "Not beneficiary");
        require(block.timestamp >= releaseTime, "Too early");
        uint256 amt = balance;
        require(amt > 0, "Nothing to withdraw");
        balance = 0;
        payable(beneficiary).transfer(amt);
        emit Withdrawn(beneficiary, amt);
    }

    function availableAt() external view returns (uint256) {
        return releaseTime;
    }
}
