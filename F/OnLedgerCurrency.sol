// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * ---------------------------------------------------------------------------
 *  On‑Ledger Currency (OLC)
 *  ---------------------------------------------------------------------------
 *  • CENTRAL_BANK_ROLE can mint (issue) and burn (redeem) supply.
 *  • TRANSFER_AGENT_ROLE can move funds on behalf of users (optional).
 *  • DEFAULT_ADMIN_ROLE (owner) may pause / unpause all transfers.
 * ---------------------------------------------------------------------------
 *  NOTE (OpenZeppelin v5.x):
 *    – Transfer hooks have been unified into `_update`.  
 *      Override `_update` (not `_beforeTokenTransfer`) to inject custom logic.
 * ---------------------------------------------------------------------------
 */
contract OnLedgerCurrency is
    ERC20,
    ERC20Burnable,
    Pausable,
    AccessControl
{
    /* Role identifiers */
    bytes32 public constant CENTRAL_BANK_ROLE   = keccak256("CENTRAL_BANK_ROLE");
    bytes32 public constant TRANSFER_AGENT_ROLE = keccak256("TRANSFER_AGENT_ROLE");

    /**
     * @param admin       Address granted DEFAULT_ADMIN_ROLE.
     * @param centralBank Address granted CENTRAL_BANK_ROLE.
     */
    constructor(address admin, address centralBank)
        ERC20("On-Ledger Currency", "OLC")   // use plain ASCII hyphen
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CENTRAL_BANK_ROLE, centralBank);
    }

    /* ────────────────── Central‑bank actions ────────────────── */

    function issue(address to, uint256 amount)
        external
        onlyRole(CENTRAL_BANK_ROLE)
    { _mint(to, amount); }

    function redeem(address from, uint256 amount)
        external
        onlyRole(CENTRAL_BANK_ROLE)
    { _burn(from, amount); }

    /* ────────────────── Optional transfer agent ─────────────── */

    function agentTransfer(address from, address to, uint256 amount)
        external
        onlyRole(TRANSFER_AGENT_ROLE)
    { _transfer(from, to, amount); }

    /* ────────────────── Pause control ───────────────────────── */

    function pause()   external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }

    /* ────────────────── Transfer hook (OZ v5.x) ─────────────── */

    /**
     * @dev OpenZeppelin v5.x funnels *all* balance changes
     *      (transfer, mint, burn) through `_update`.
     *      We inject the pause check here, then defer to parent logic.
     */
    function _update(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Burnable)
    {
        require(!paused(), "OLC: transfers paused");
        super._update(from, to, amount);
    }
}
