// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ERC20Faucet
 * @dev A faucet that dispenses a fixed amount of a specific ERC20 token to users after a cooldown.
 */
contract ERC20Faucet is Ownable {
    IERC20 public token;
    // Amount of tokens dispensed per claim.
    uint256 public claimAmount;
    // Cooldown time (in seconds) between claims.
    uint256 public cooldownTime;
    // Tracks last claim timestamp for each address.
    mapping(address => uint256) public lastClaimed;

    event Claimed(address indexed user, uint256 amount);
    event ClaimAmountUpdated(uint256 newClaimAmount);
    event CooldownTimeUpdated(uint256 newCooldownTime);

    /**
     * @dev Constructor sets the ERC20 token address, claim amount, and cooldown time.
     * @param _token Address of the ERC20 token.
     * @param _claimAmount Amount of tokens to dispense per claim.
     * @param _cooldownTime Cooldown time in seconds between claims.
     */
    constructor(
        IERC20 _token,
        uint256 _claimAmount,
        uint256 _cooldownTime
    ) Ownable(msg.sender) {
        token = _token;
        claimAmount = _claimAmount;
        cooldownTime = _cooldownTime;
    }

    /**
     * @dev Allows a user to claim tokens.
     */
    function claim() external {
        require(block.timestamp - lastClaimed[msg.sender] >= cooldownTime, "Wait before claiming again");
        require(token.balanceOf(address(this)) >= claimAmount, "Faucet empty");

        lastClaimed[msg.sender] = block.timestamp;
        token.transfer(msg.sender, claimAmount);
        emit Claimed(msg.sender, claimAmount);
    }

    /**
     * @dev Allows the owner to withdraw tokens from the faucet.
     */
    function withdrawTokens(uint256 amount) external onlyOwner {
        token.transfer(owner(), amount);
    }

    /**
     * @dev Allows the owner to update the claim amount.
     */
    function setClaimAmount(uint256 _claimAmount) external onlyOwner {
        claimAmount = _claimAmount;
        emit ClaimAmountUpdated(_claimAmount);
    }

    /**
     * @dev Allows the owner to update the cooldown time.
     */
    function setCooldownTime(uint256 _cooldownTime) external onlyOwner {
        cooldownTime = _cooldownTime;
        emit CooldownTimeUpdated(_cooldownTime);
    }
}
