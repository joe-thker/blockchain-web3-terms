// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title StableCoin
/// @notice An ERC20 token representing a stablecoin pegged to a fiat currency.
contract StableCoin is ERC20, Ownable {
    // Peg value (for reference only)
    uint256 public peg;

    constructor(uint256 initialSupply, uint256 _peg) ERC20("StableCoin", "STBL") Ownable(msg.sender) {
        peg = _peg;
        _mint(msg.sender, initialSupply);
    }

    /// @notice Owner can adjust the peg.
    function adjustPeg(uint256 newPeg) external onlyOwner {
        peg = newPeg;
    }

    /// @notice Owner can mint additional tokens.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice Allows token holders to burn tokens.
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
