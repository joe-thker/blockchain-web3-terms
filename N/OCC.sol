// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OfficeOfComptrollerCurrency
 * @notice An ERC‑20 “OCC” token implementing on‑chain regulatory controls:
 *         – Only whitelisted (KYC’d) addresses may hold or transfer tokens.
 *         – The OCC (owner) can pause all transfers.
 *         – The OCC can mint and burn tokens.
 */
contract OfficeOfComptrollerCurrency is ERC20, ERC20Burnable, Pausable, Ownable {
    /// @notice Addresses approved to hold and transfer OCC tokens.
    mapping(address => bool) public whitelist;

    event Whitelisted(address indexed account);
    event Dewhitelisted(address indexed account);

    /**
     * @param initialSupply Initial OCC minted to the deployer (owner).
     */
    constructor(uint256 initialSupply)
        ERC20("OfficeOfComptrollerCurrency", "OCC")
        Ownable(msg.sender)
    {
        // Deployer is automatically whitelisted
        whitelist[msg.sender] = true;
        emit Whitelisted(msg.sender);
        _mint(msg.sender, initialSupply);
    }

    /// @notice Pause all token transfers. Only OCC (owner) may call.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause token transfers. Only OCC (owner) may call.
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Add an address to the whitelist (KYC approved).
     * @param account The address to whitelist.
     */
    function addToWhitelist(address account) external onlyOwner {
        require(!whitelist[account], "Already whitelisted");
        whitelist[account] = true;
        emit Whitelisted(account);
    }

    /**
     * @notice Remove an address from the whitelist (revoke KYC).
     * @param account The address to dewhitelist.
     */
    function removeFromWhitelist(address account) external onlyOwner {
        require(whitelist[account], "Not whitelisted");
        whitelist[account] = false;
        emit Dewhitelisted(account);
    }

    /**
     * @notice Mint new OCC tokens to a whitelisted address.
     * @param to     Recipient (must be whitelisted).
     * @param amount Amount of OCC to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(whitelist[to], "Recipient not whitelisted");
        _mint(to, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     *      minting and burning.
     *
     *      We override ERC20._beforeTokenTransfer to:
     *      - Prevent transfers while paused.
     *      - Enforce whitelist on sender/recipient (except mint/burn).
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "Token transfer while paused");

        // Allow minting (from == address(0)) and burning (to == address(0))
        if (from != address(0)) {
            require(whitelist[from], "Sender not whitelisted");
        }
        if (to != address(0)) {
            require(whitelist[to], "Recipient not whitelisted");
        }
    }
}
