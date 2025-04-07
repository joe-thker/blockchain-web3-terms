// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FiatOnRampERC20
 * @dev ERC20 token that acts as a fiat on-ramp.
 * Users deposit ETH to receive tokens at a fixed conversion rate (tokensPerEth).
 * The owner can update the conversion rate and withdraw the collected ETH.
 */
contract FiatOnRampERC20 is ERC20, Ownable {
    // Conversion rate: number of tokens (with 18 decimals) minted per 1 ETH deposited.
    uint256 public tokensPerEth;

    event Deposited(address indexed user, uint256 ethAmount, uint256 tokenAmount);
    event RateUpdated(uint256 newRate);
    event Withdrawn(address indexed owner, uint256 amount);

    /**
     * @dev Constructor sets the token name, symbol, and initial conversion rate.
     * @param initialRate Number of tokens (with 18 decimals) minted per 1 ETH.
     */
    constructor(uint256 initialRate)
        ERC20("Fiat On-Ramp Token", "FORT")
        Ownable(msg.sender)
    {
        require(initialRate > 0, "Rate must be > 0");
        tokensPerEth = initialRate;
    }

    /**
     * @dev Deposit ETH to receive tokens.
     * The number of tokens minted equals: (msg.value * tokensPerEth) / 1 ether.
     */
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        uint256 tokenAmount = (msg.value * tokensPerEth) / 1 ether;
        _mint(msg.sender, tokenAmount);
        emit Deposited(msg.sender, msg.value, tokenAmount);
    }

    /**
     * @dev Allows the owner to update the conversion rate.
     * @param newRate New tokens per ETH rate (with 18 decimals).
     */
    function setRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Rate must be > 0");
        tokensPerEth = newRate;
        emit RateUpdated(newRate);
    }

    /**
     * @dev Allows the owner to withdraw accumulated ETH from the contract.
     * @param amount Amount of ETH (in wei) to withdraw.
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner()).transfer(amount);
        emit Withdrawn(owner(), amount);
    }

    /**
     * @dev Fallback function to accept ETH deposits.
     */
    receive() external payable {
        deposit();
    }
}
