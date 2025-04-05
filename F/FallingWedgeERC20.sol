// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FallingWedgeToken
 * @dev ERC20 token with a dynamic burn fee that increases over time.
 * The burn fee (in basis points) starts at minBurnFee and increases linearly (per day)
 * until it reaches maxBurnFee. On each transfer a portion of the tokens are burned.
 */
contract FallingWedgeToken is ERC20, Ownable {
    // Minimum burn fee in basis points (e.g., 50 = 0.5%)
    uint256 public minBurnFee;
    // Maximum burn fee in basis points (e.g., 1000 = 10%)
    uint256 public maxBurnFee;
    // Burn fee increase rate per day in basis points (e.g., 10 = 0.1% per day)
    uint256 public burnFeeIncreaseRate;
    // Timestamp when the contract was deployed
    uint256 public deploymentTime;

    event BurnFeeApplied(uint256 currentFee, uint256 burnAmount);

    /**
     * @dev Constructor sets token details, initial supply, and burn fee parameters.
     * @param initialSupply Total token supply in the smallest unit.
     * @param _minBurnFee Minimum burn fee in basis points.
     * @param _maxBurnFee Maximum burn fee in basis points.
     * @param _burnFeeIncreaseRate Burn fee increase rate per day in basis points.
     */
    constructor(
        uint256 initialSupply,
        uint256 _minBurnFee,
        uint256 _maxBurnFee,
        uint256 _burnFeeIncreaseRate
    ) ERC20("Falling Wedge Token", "FWT") Ownable(msg.sender) {
        require(_minBurnFee <= _maxBurnFee, "Min burn fee must be <= max burn fee");
        minBurnFee = _minBurnFee;
        maxBurnFee = _maxBurnFee;
        burnFeeIncreaseRate = _burnFeeIncreaseRate;
        deploymentTime = block.timestamp;
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Returns the current burn fee in basis points based on elapsed days.
     */
    function currentBurnFee() public view returns (uint256) {
        uint256 elapsedDays = (block.timestamp - deploymentTime) / 1 days;
        uint256 fee = minBurnFee + (elapsedDays * burnFeeIncreaseRate);
        if (fee > maxBurnFee) {
            fee = maxBurnFee;
        }
        return fee;
    }

    /**
     * @dev Overrides transfer to apply the dynamic burn fee.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = currentBurnFee();
        uint256 burnAmount = (amount * fee) / 10000;
        uint256 sendAmount = amount - burnAmount;

        bool success = super.transfer(recipient, sendAmount);
        require(success, "Transfer failed");

        _burn(_msgSender(), burnAmount);
        emit BurnFeeApplied(fee, burnAmount);
        return true;
    }

    /**
     * @dev Overrides transferFrom to apply the dynamic burn fee.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = currentBurnFee();
        uint256 burnAmount = (amount * fee) / 10000;
        uint256 sendAmount = amount - burnAmount;

        bool success = super.transferFrom(sender, recipient, sendAmount);
        require(success, "Transfer failed");

        _burn(sender, burnAmount);
        emit BurnFeeApplied(fee, burnAmount);
        return true;
    }
}
