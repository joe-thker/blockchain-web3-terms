// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FallingKnifeToken
 * @dev ERC20 token that burns a percentage of tokens on every transfer.
 * The burn fee is set in basis points (100 basis points = 1%).
 */
contract FallingKnifeToken is ERC20, Ownable {
    // Burn fee in basis points (for example, 50 means 0.5%)
    uint256 public burnFee;

    event BurnFeeUpdated(uint256 newBurnFee);

    /**
     * @dev Constructor that sets the token details, initial supply, and burn fee.
     * @param initialSupply Total token supply in the smallest units.
     * @param _burnFee Burn fee in basis points.
     */
    constructor(uint256 initialSupply, uint256 _burnFee)
        ERC20("Falling Knife Token", "FKT")
        Ownable(msg.sender)
    {
        // Optionally cap the burn fee (for example, at 10% or 1000 basis points)
        require(_burnFee <= 1000, "Burn fee too high");
        burnFee = _burnFee;
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Allows the owner to update the burn fee.
     * @param newBurnFee New burn fee in basis points.
     */
    function updateBurnFee(uint256 newBurnFee) external onlyOwner {
        require(newBurnFee <= 1000, "Burn fee too high");
        burnFee = newBurnFee;
        emit BurnFeeUpdated(newBurnFee);
    }

    /**
     * @dev Overrides the public transfer function to implement the burn mechanism.
     * The sender's account is debited the full amount while the recipient receives (amount - burnFee).
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        // Calculate burn amount
        uint256 burnAmount = (amount * burnFee) / 10000;
        uint256 sendAmount = amount - burnAmount;

        // Transfer sendAmount to recipient
        bool success = super.transfer(recipient, sendAmount);
        require(success, "Transfer failed");

        // Burn the calculated burnAmount from sender
        _burn(msg.sender, burnAmount);
        return true;
    }

    /**
     * @dev Overrides the public transferFrom function to implement the burn mechanism.
     * The sender's account is debited the full amount while the recipient receives (amount - burnFee).
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        // Calculate burn amount
        uint256 burnAmount = (amount * burnFee) / 10000;
        uint256 sendAmount = amount - burnAmount;

        // Transfer sendAmount to recipient using the parent's transferFrom logic (which handles allowances)
        bool success = super.transferFrom(sender, recipient, sendAmount);
        require(success, "Transfer failed");

        // Burn the calculated burnAmount from sender
        _burn(sender, burnAmount);
        return true;
    }
}
