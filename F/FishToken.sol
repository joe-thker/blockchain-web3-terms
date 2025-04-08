// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FishToken
 * @dev ERC20 token representing a standardized fish commodity.
 * The owner (e.g., a fishery) can mint new tokens representing fish caught.
 */
contract FishToken is ERC20, Ownable {
    /**
     * @dev Constructor that mints the initial supply to the deployer.
     * @param initialSupply Total initial supply in the smallest unit (e.g., if using 18 decimals, 1000 tokens = 1000 * 10^18).
     */
    constructor(uint256 initialSupply)
        ERC20("Fish Token", "FISH")
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @notice Mints new Fish tokens.
     * @param to The address that will receive the new tokens.
     * @param amount The number of tokens to mint.
     */
    function catchFish(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
