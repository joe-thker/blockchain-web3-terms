// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin's ERC20 and Ownable contracts.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CentralBankDigitalCurrency
/// @notice An ERC20 token simulating a Central Bank Digital Currency (CBDC).
/// The owner (central bank) can mint and burn tokens, representing money issuance and reduction.
contract CentralBankDigitalCurrency is ERC20, Ownable {
    /// @notice Constructor initializes the CBDC with a name, symbol, and an initial supply minted to the owner.
    /// @param initialSupply The total initial supply of the token (in the smallest unit, e.g., wei for 18 decimals).
    constructor(uint256 initialSupply) ERC20("Central Bank Digital Currency", "CBDC") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }
    
    /// @notice Allows the owner to mint new CBDC tokens.
    /// @param to The address to receive the newly minted tokens.
    /// @param amount The number of tokens to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /// @notice Allows any token holder to burn tokens from their balance, reducing the total supply.
    /// @param amount The number of tokens to burn.
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
