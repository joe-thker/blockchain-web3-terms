// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

/**
 * @title MetaTransactionExample
 * @notice Demonstrates ERC‑2771 meta‑transactions via OpenZeppelin’s MinimalForwarder.
 */
contract MetaTransactionExample is ERC2771Context, Ownable {
    event ActionPerformed(address indexed user, string data);

    constructor(MinimalForwarder forwarder) 
        ERC2771Context(address(forwarder)) 
        Ownable(msg.sender) 
    {}

    /// @notice Anyone (via the forwarder) can call this; _msgSender() is the original user.
    function performAction(string calldata data) external {
        address user = _msgSender();
        emit ActionPerformed(user, data);
    }

    /// @notice Owner can withdraw any ETH held here.
    function withdraw(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    receive() external payable {}

    // ──────────────────────────────────────────────────────────────────────────
    // Required overrides to disambiguate Context vs. ERC2771Context
    // ──────────────────────────────────────────────────────────────────────────

    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength()
        internal
        view
        override(Context, ERC2771Context)
        returns (uint256)
    {
        return ERC2771Context._contextSuffixLength();
    }
}
