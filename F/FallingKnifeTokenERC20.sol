// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FallingKnifeToken
 * @dev ERC20 token that burns a percentage of tokens on every transfer.
 */
contract FallingKnifeToken is ERC20, Ownable {
    // Burn fee in basis points (e.g., 50 = 0.5%)
    uint256 public burnFee;

    event BurnFeeUpdated(uint256 newBurnFee);

    /**
     * @dev Constructor sets the token details, initial supply, and burn fee.
     * @param initialSupply Total token supply (in smallest units).
     * @param _burnFee Burn fee in basis points.
     */
    constructor(uint256 initialSupply, uint256 _burnFee)
        ERC20("Falling Knife Token", "FKT")
        Ownable(msg.sender)
    {
        // Cap burn fee at 10% (1000 basis points)
        require(_burnFee <= 1000, "Burn fee too high");
        burnFee = _burnFee;
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Allows the owner to update the burn fee.
     */
    function updateBurnFee(uint256 newBurnFee) external onlyOwner {
        require(newBurnFee <= 1000, "Burn fee too high");
        burnFee = newBurnFee;
        emit BurnFeeUpdated(newBurnFee);
    }

    /**
     * @dev Overrides the public transfer function to burn a fee on each transfer.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * burnFee) / 10000;
        uint256 sendAmount = amount - fee;
        bool success = super.transfer(recipient, sendAmount);
        require(success, "Transfer failed");
        _burn(msg.sender, fee);
        return true;
    }

    /**
     * @dev Overrides the public transferFrom function to burn a fee on each transfer.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * burnFee) / 10000;
        uint256 sendAmount = amount - fee;
        bool success = super.transferFrom(sender, recipient, sendAmount);
        require(success, "Transfer failed");
        _burn(sender, fee);
        return true;
    }
}
