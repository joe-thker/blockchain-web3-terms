// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title UtilityToken - Basic ERC20 utility token for dApp use
contract UtilityToken is ERC20, Ownable {
    constructor() ERC20("AccessToken", "ATK") {
        _mint(msg.sender, 1_000_000 * 10**18); // Initial supply
    }

    /// @notice Spend tokens to access feature
    function spend(uint256 amount) external {
        _burn(msg.sender, amount);
        // logic to grant access can be handled off-chain or via event
        emit TokenUsed(msg.sender, amount);
    }

    event TokenUsed(address indexed user, uint256 amount);
}
