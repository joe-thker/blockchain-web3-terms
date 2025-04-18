// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/**
 * @title OffChainERC20Permit
 * @notice An ERC‑20 token with EIP‑2612 permit so approvals can happen off‑chain.
 *         Relayer can then call `permitAndTransfer` to move tokens.
 */
contract OffChainERC20Permit is ERC20Permit {
    constructor()
        ERC20("OffChainToken", "OCT")
        ERC20Permit("OffChainToken")
    {}

    /**
     * @notice Permit `spender` and immediately transfer `amount` from `owner` to `to`.
     * @param owner    Token holder address.
     * @param spender  Relayer address approved to spend.
     * @param to       Recipient of the transfer.
     * @param amount   Amount to transfer.
     * @param deadline Permit signature expiry.
     * @param v,r,s    Permit signature.
     */
    function permitAndTransfer(
        address owner,
        address spender,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        // Off‑chain signed permit:
        permit(owner, spender, amount, deadline, v, r, s);
        // Now transfer (must be called by spender)
        require(msg.sender == spender, "Not approved relayer");
        _transfer(owner, to, amount);
    }
}
