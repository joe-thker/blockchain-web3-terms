// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * Regulated On‑Ledger Currency (ROLC)
 * – CENTRAL_BANK_ROLE  : mint / burn
 * – TRANSFER_AGENT_ROLE: move balances without allowance
 * – DEFAULT_ADMIN_ROLE : pause / unpause
 */
contract RegulatedOLC is
    ERC20,
    ERC20Burnable,
    AccessControl,
    Pausable
{
    bytes32 public constant CENTRAL_BANK_ROLE   = keccak256("CENTRAL_BANK_ROLE");
    bytes32 public constant TRANSFER_AGENT_ROLE = keccak256("TRANSFER_AGENT_ROLE");

    constructor(
        address admin,
        address centralBank
    )
        ERC20("Regulated On‑Ledger Currency", "ROLC")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CENTRAL_BANK_ROLE,  centralBank);
    }

    /* ────── Central‑bank actions ────── */
    function issue(address to, uint256 amt) external onlyRole(CENTRAL_BANK_ROLE) {
        _mint(to, amt);
    }
    function redeem(address from, uint256 amt) external onlyRole(CENTRAL_BANK_ROLE) {
        _burn(from, amt);
    }

    /* ────── Optional transfer agent ────── */
    function agentTransfer(address from, address to, uint256 amt)
        external
        onlyRole(TRANSFER_AGENT_ROLE)
    { _transfer(from, to, amt); }

    /* ────── Pause control ────── */
    function pause()   external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }

    /* ────── Hook (OZ v5.x) ────── */
    function _update(address from, address to, uint256 amt)
        internal
        override(ERC20, ERC20Burnable)
    {
        require(!paused(), "ROLC: paused");
        super._update(from, to, amt);
    }
}
