// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OfficeOfComptrollerPausable
 * @notice ERC‑20 OCC token with pause functionality.
 *         – Owner can mint, burn, pause, and unpause.
 */
contract OfficeOfComptrollerPausable is ERC20, ERC20Burnable, Pausable, Ownable {
    /**
     * @param initialSupply Initial OCC minted to the deployer (owner).
     */
    constructor(uint256 initialSupply)
        ERC20("OfficeOfComptrollerCurrency", "OCC")
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Pause all token transfers.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause token transfers.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Mint new OCC tokens. Only the owner may call.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     *      minting and burning. Prevents transfers while paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "OCC: token transfer while paused");
    }
}
