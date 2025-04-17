// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title BasicNonce
 * @notice Tracks a single nonce per address.  
 *         - getNonce(addr): view current nonce  
 *         - useNonce(): returns & increments msg.sender’s nonce  
 *         - incrementNonce(): skip a nonce without reading it
 */
contract BasicNonce {
    mapping(address => uint256) private _nonces;

    event NonceUsed(address indexed user, uint256 oldNonce, uint256 newNonce);

    /// @notice Returns the current nonce for `user`.
    function getNonce(address user) external view returns (uint256) {
        return _nonces[user];
    }

    /**
     * @notice Consumes & returns msg.sender’s nonce, then increments it.
     * @return The nonce value before increment.
     */
    function useNonce() external returns (uint256) {
        uint256 current = _nonces[msg.sender];
        _nonces[msg.sender] = current + 1;
        emit NonceUsed(msg.sender, current, current + 1);
        return current;
    }

    /// @notice Increments msg.sender’s nonce without returning it.
    function incrementNonce() external {
        uint256 current = _nonces[msg.sender];
        _nonces[msg.sender] = current + 1;
        emit NonceUsed(msg.sender, current, current + 1);
    }
}
