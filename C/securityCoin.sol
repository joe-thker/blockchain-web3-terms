// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SecurityCoin
/// @notice An ERC20 token with a simple whitelist for compliance, representing a security coin.
/// It modifies token transfers to require that both sender and receiver are whitelisted.
contract SecurityCoin is ERC20, Ownable {
    mapping(address => bool) public whitelisted;

    event Whitelisted(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    constructor(uint256 initialSupply) ERC20("SecurityCoin", "SEC") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
        whitelisted[msg.sender] = true;
    }

    /// @notice Adds an address to the whitelist.
    function addToWhitelist(address account) external onlyOwner {
        whitelisted[account] = true;
        emit Whitelisted(account);
    }

    /// @notice Removes an address from the whitelist.
    function removeFromWhitelist(address account) external onlyOwner {
        whitelisted[account] = false;
        emit RemovedFromWhitelist(account);
    }

    /// @notice Modifies token transfers to require that both sender and receiver are whitelisted.
    /// This function is called before any token transfer occurs.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal {
        // Skip the check for minting and burning.
        if (from != address(0) && to != address(0)) {
            require(whitelisted[from] && whitelisted[to], "Both addresses must be whitelisted");
        }
    }
}
