// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Faucet
 * @dev A simple ETH faucet that allows users to claim a fixed amount of ETH after a cooldown period.
 */
contract Faucet is Ownable {
    // The amount of ETH (in wei) dispensed per claim.
    uint256 public dripAmount;
    // Cooldown time (in seconds) between claims per address.
    uint256 public cooldownTime;
    // Mapping to track the last claim time for each address.
    mapping(address => uint256) public lastClaimed;

    // Emitted when a user successfully claims ETH.
    event Dripped(address indexed user, uint256 amount);
    // Emitted when the drip amount is updated.
    event DripAmountUpdated(uint256 newDripAmount);
    // Emitted when the cooldown time is updated.
    event CooldownTimeUpdated(uint256 newCooldownTime);

    /**
     * @dev Sets the initial drip amount and cooldown time.
     * @param _dripAmount The amount of ETH (in wei) to dispense per claim.
     * @param _cooldownTime The cooldown time (in seconds) between claims for a single address.
     */
    constructor(uint256 _dripAmount, uint256 _cooldownTime)
        Ownable(msg.sender)
    {
        dripAmount = _dripAmount;
        cooldownTime = _cooldownTime;
    }

    /**
     * @dev Allows a user to claim ETH from the faucet.
     * Requirements:
     * - The faucet must have enough balance.
     * - The user must wait until the cooldown period has passed.
     */
    function claim() external {
        require(address(this).balance >= dripAmount, "Faucet empty, try again later");
        require(
            block.timestamp - lastClaimed[msg.sender] >= cooldownTime,
            "Please wait before claiming again"
        );

        lastClaimed[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(dripAmount);

        emit Dripped(msg.sender, dripAmount);
    }

    /**
     * @dev Fallback function to allow the contract to receive ETH.
     */
    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev Allows the owner to withdraw ETH from the contract.
     * @param amount The amount to withdraw in wei.
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner()).transfer(amount);
    }

    /**
     * @dev Allows the owner to update the drip amount.
     * @param _dripAmount New drip amount in wei.
     */
    function setDripAmount(uint256 _dripAmount) external onlyOwner {
        dripAmount = _dripAmount;
        emit DripAmountUpdated(_dripAmount);
    }

    /**
     * @dev Allows the owner to update the cooldown time.
     * @param _cooldownTime New cooldown time in seconds.
     */
    function setCooldownTime(uint256 _cooldownTime) external onlyOwner {
        cooldownTime = _cooldownTime;
        emit CooldownTimeUpdated(_cooldownTime);
    }
}
