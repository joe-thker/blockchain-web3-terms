// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OfficeOfComptrollerRegulated
 * @notice ERC‑20 OCC token with pause and KYC whitelist:
 *         – Only whitelisted addresses may send or receive.
 *         – Owner can mint, burn, pause/unpause, and manage KYC whitelist.
 */
contract OfficeOfComptrollerRegulated is ERC20, ERC20Burnable, Pausable, Ownable {
    mapping(address => bool) public whitelist;

    event Whitelisted(address indexed account);
    event Dewhitelisted(address indexed account);

    constructor(uint256 initialSupply)
        ERC20("OfficeOfComptrollerCurrency", "OCC")
        Ownable(msg.sender)
    {
        // Owner starts whitelisted
        whitelist[msg.sender] = true;
        emit Whitelisted(msg.sender);
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

    /// @notice Add `account` to the KYC whitelist.
    function addToWhitelist(address account) external onlyOwner {
        require(!whitelist[account], "OCC: already whitelisted");
        whitelist[account] = true;
        emit Whitelisted(account);
    }

    /// @notice Remove `account` from the KYC whitelist.
    function removeFromWhitelist(address account) external onlyOwner {
        require(whitelist[account], "OCC: not whitelisted");
        whitelist[account] = false;
        emit Dewhitelisted(account);
    }

    /// @notice Mint OCC to a whitelisted address.
    function mint(address to, uint256 amount) external onlyOwner {
        require(whitelist[to], "OCC: recipient not whitelisted");
        _mint(to, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     *      minting and burning.
     *
     *      Prevents transfers while paused and enforces whitelist on sender/recipient
     *      (except when minting or burning).
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "OCC: token transfer while paused");

        // Allow minting (from == address(0)) and burning (to == address(0))
        if (from != address(0)) {
            require(whitelist[from], "OCC: sender not whitelisted");
        }
        if (to != address(0)) {
            require(whitelist[to], "OCC: recipient not whitelisted");
        }
    }
}
