// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * Regulated On‑Chain Fiat (RUSD)
 * ────────────────────────────────────────────────────────────
 *  • DEFAULT_ADMIN_ROLE  – pause / unpause, manage roles
 *  • ISSUER_ROLE         – mint (issue) and burn (redeem)
 *  • COMPLIANCE_ROLE     – manage blacklist
 *  • TRANSFER_AGENT_ROLE – force transfers without allowance
 */
contract RegulatedFiat is
    ERC20,
    ERC20Burnable,
    AccessControl,
    Pausable
{
    bytes32 public constant ISSUER_ROLE         = keccak256("ISSUER_ROLE");
    bytes32 public constant COMPLIANCE_ROLE     = keccak256("COMPLIANCE_ROLE");
    bytes32 public constant TRANSFER_AGENT_ROLE = keccak256("TRANSFER_AGENT_ROLE");

    mapping(address => bool) public blacklisted;

    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);

    constructor(address admin, address issuer)
        ERC20("Regulated On-Chain Fiat USD", "RUSD") // ASCII hyphen
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER_ROLE,         issuer);
    }

    /* ────────────── Monetary control ────────────── */

    function issue(address to, uint256 amount)
        external
        onlyRole(ISSUER_ROLE)
    { _mint(to, amount); }

    function redeem(address from, uint256 amount)
        external
        onlyRole(ISSUER_ROLE)
    { _burn(from, amount); }

    /* ────────────── Compliance control ────────────── */

    function blacklist(address account)
        external
        onlyRole(COMPLIANCE_ROLE)
    { blacklisted[account] = true; emit Blacklisted(account); }

    function unblacklist(address account)
        external
        onlyRole(COMPLIANCE_ROLE)
    { blacklisted[account] = false; emit UnBlacklisted(account); }

    /* ────────────── Agent transfer ────────────── */

    function agentTransfer(address from, address to, uint256 amount)
        external
        onlyRole(TRANSFER_AGENT_ROLE)
    { _transfer(from, to, amount); }

    /* ────────────── Pause control ────────────── */

    function pause()   external onlyRole(DEFAULT_ADMIN_ROLE) { _pause();  }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause();}

    /* ────────────── Single transfer hook (OZ v5.x) ────────────── */

    /**
     * Override list now only includes **ERC20** because
     * ERC20Burnable does *not* override `_update`.
     */
    function _update(address from, address to, uint256 amount)
        internal
        override(ERC20)
    {
        if (paused()) {
            bool issuerBurn = (to == address(0)) && hasRole(ISSUER_ROLE, msg.sender);
            require(issuerBurn || from == address(0), "RUSD: paused");
        }
        if (from != address(0)) require(!blacklisted[from], "RUSD: sender blacklisted");
        if (to   != address(0)) require(!blacklisted[to],   "RUSD: recipient blacklisted");

        super._update(from, to, amount);
    }
}
