// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*  OpenZeppelin v5.x */
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * ============================================================================
 *  On‑Chain Fiat (OCF)
 *  --------------------------------------------------------------------------
 *  •   DEFAULT_ADMIN_ROLE   — super‑user (treasury / regulator)
 *  •   ISSUER_ROLE          — mints (issues) and burns (redeems) supply
 *  •   COMPLIANCE_ROLE      — blacklists / un‑blacklists addresses
 *  •   TRANSFER_AGENT_ROLE  — can transfer on behalf of users (court orders,
 *                             recovery, regulated settlement, etc.)
 *
 *  Extra Features
 *  ---------------
 *  •   Pause switch (admin) halts *all* transfers except ISSUER_ROLE burns.
 *  •   Address blacklist enforced in `_update` hook (OZ v5 token transfer hook)
 *  •   ASCII hyphen in name avoids Unicode parser errors.
 * ============================================================================
 */
contract OnchainFiat is
    ERC20Burnable,
    Pausable,
    AccessControl
{
    /* ───────────────────── Roles ───────────────────── */
    bytes32 public constant ISSUER_ROLE         = keccak256("ISSUER_ROLE");
    bytes32 public constant COMPLIANCE_ROLE     = keccak256("COMPLIANCE_ROLE");
    bytes32 public constant TRANSFER_AGENT_ROLE = keccak256("TRANSFER_AGENT_ROLE");

    /* ─────────────  Blacklist mapping  ───────────── */
    mapping(address => bool) public blacklisted;

    /* ─────────────  Events  ───────────── */
    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);

    /* ─────────────  Constructor  ───────────── */
    constructor(address admin, address issuer)
        ERC20("Onchain Fiat USD", "OCUSD")      // <‑‑ ASCII hyphen
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER_ROLE,         issuer);
        /* Optionally: grant issuer compliance / transfer agent if desired */
    }

    /* ─────────────  Admin / Issuer Actions  ───────────── */

    /// Issue new fiat tokens
    function issue(address to, uint256 amount)
        external
        onlyRole(ISSUER_ROLE)
    { _mint(to, amount); }

    /// Redeem (burn) tokens from `from`
    function redeem(address from, uint256 amount)
        external
        onlyRole(ISSUER_ROLE)
    { _burn(from, amount); }

    /// Blacklist an address (compliance)
    function blacklist(address account)
        external
        onlyRole(COMPLIANCE_ROLE)
    {
        blacklisted[account] = true;
        emit Blacklisted(account);
    }

    /// Remove address from blacklist
    function unblacklist(address account)
        external
        onlyRole(COMPLIANCE_ROLE)
    {
        blacklisted[account] = false;
        emit UnBlacklisted(account);
    }

    /// Force transfer by compliance/agent
    function agentTransfer(address from, address to, uint256 amount)
        external
        onlyRole(TRANSFER_AGENT_ROLE)
    { _transfer(from, to, amount); }

    /// Pause / unpause by admin
    function pause()   external onlyRole(DEFAULT_ADMIN_ROLE) { _pause();  }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause();}

    /* ─────────────  Internal Transfer Hook  ─────────────
     *  OpenZeppelin v5 funnels everything through _update.
     */
    function _update(address from, address to, uint256 amount)
        internal
        override
    {
        // still allow issuer burns even while paused
        if (paused()) {
            // mint (from=0), burn (to=0) or issuer burn allowed
            bool issuerBurn = (to == address(0)) && hasRole(ISSUER_ROLE, msg.sender);
            require(issuerBurn || from == address(0), "OCF: paused");
        }

        if (from != address(0)) require(!blacklisted[from], "OCF: sender blacklisted");
        if (to   != address(0)) require(!blacklisted[to],   "OCF: recipient blacklisted");

        super._update(from, to, amount);
    }
}
