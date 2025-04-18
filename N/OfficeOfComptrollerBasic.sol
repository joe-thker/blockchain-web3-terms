// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OfficeOfComptrollerBasic
 * @notice A simple ERC‑20 OCC token. Only the owner may mint or burn.
 */
contract OfficeOfComptrollerBasic is ERC20, Ownable {
    constructor(uint256 initialSupply)
        ERC20("OfficeOfComptrollerCurrency", "OCC")
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Mint new OCC tokens. Only the owner may call.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice Burn OCC tokens from the owner’s balance. Only owner.
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }
}
