// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Nonce
 * @notice A simple on‑chain nonce manager for replay protection.
 *         Tracks a per‑address counter that can be read and consumed.
 */
contract Nonce {
    // Mapping from user address to their current nonce.
    mapping(address => uint256) private _nonces;

    /// @notice Emitted when a user's nonce is advanced.
    event NonceUsed(address indexed user, uint256 oldNonce, uint256 newNonce);

    /**
     * @notice Returns the current nonce for a given user.
     * @param user The address whose nonce to query.
     * @return The current nonce.
     */
    function getNonce(address user) external view returns (uint256) {
        return _nonces[user];
    }

    /**
     * @notice Consumes and returns the caller's current nonce, then increments it.
     * @dev Use this in meta‑transaction or replay‑protected logic:
     *      uint256 nonce = nonceContract.useNonce();
     *      bytes32 hash = keccak256(abi.encodePacked(..., nonce));
     * @return The nonce value before incrementing.
     */
    function useNonce() external returns (uint256) {
        uint256 current = _nonces[msg.sender];
        _nonces[msg.sender] = current + 1;
        emit NonceUsed(msg.sender, current, current + 1);
        return current;
    }

    /**
     * @notice Manually increments the caller's nonce without returning the old value.
     * @dev Can be used to skip a nonce or invalidate pending actions.
     */
    function incrementNonce() external {
        uint256 current = _nonces[msg.sender];
        _nonces[msg.sender] = current + 1;
        emit NonceUsed(msg.sender, current, current + 1);
    }
}
