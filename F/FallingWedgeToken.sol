// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FallingWedgeToken
 * @dev ERC20 token with a dynamic burn fee that increases over time.
 * The burn fee is calculated in basis points (1% = 100 basis points) using:
 *
 *     currentBurnFee = minBurnFee + (elapsedDays * burnFeeIncreaseRate)
 *
 * The fee is capped at maxBurnFee. On every transfer, the calculated burn fee is applied—
 * burning a portion of the transferred tokens.
 */
contract FallingWedgeToken is ERC20, Ownable {
    // Minimum burn fee in basis points (e.g., 50 = 0.5%)
    uint256 public minBurnFee;
    // Maximum burn fee in basis points (e.g., 1000 = 10%)
    uint256 public maxBurnFee;
    // Burn fee increase rate per day in basis points (e.g., 10 basis points per day)
    uint256 public burnFeeIncreaseRate;
    // Timestamp at deployment (used to compute elapsed days)
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
     * @dev Returns the current burn fee (in basis points) based on elapsed days since deployment.
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
     * @dev Overrides transfer to apply a dynamic burn fee.
     * The sender sends (amount - burnAmount) to the recipient and burnAmount is burned.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = currentBurnFee();
        uint256 burnAmount = (amount * fee) / 10000;
        uint256 sendAmount = amount - burnAmount;

        // Transfer the net amount
        bool success = super.transfer(recipient, sendAmount);
        require(success, "Transfer failed");

        // Burn the fee from the sender's balance
        _burn(_msgSender(), burnAmount);
        emit BurnFeeApplied(fee, burnAmount);
        return true;
    }

    /**
     * @dev Overrides transferFrom to apply a dynamic burn fee.
     * The sender’s tokens are reduced by the burn fee before transfer.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = currentBurnFee();
        uint256 burnAmount = (amount * fee) / 10000;
        uint256 sendAmount = amount - burnAmount;

        // Transfer the net amount
        bool success = super.transferFrom(sender, recipient, sendAmount);
        require(success, "Transfer failed");

        // Burn the fee from the sender's balance
        _burn(sender, burnAmount);
        emit BurnFeeApplied(fee, burnAmount);
        return true;
    }
}
