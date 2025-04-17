// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AdminResetNonce
 * @notice Per‑address nonces with owner authority to reset.
 *         - Users: getNonce, useNonce, incrementNonce  
 *         - Owner: resetNonce(user, newValue)
 */
contract AdminResetNonce is Ownable {
    mapping(address => uint256) private _nonces;

    event NonceUsed(address indexed user, uint256 oldNonce, uint256 newNonce);
    event NonceReset(address indexed user, uint256 oldNonce, uint256 newNonce);

    constructor() Ownable(msg.sender) {}

    /// @notice Returns the current nonce for `user`.
    function getNonce(address user) external view returns (uint256) {
        return _nonces[user];
    }

    /**
     * @notice Returns & increments msg.sender’s nonce.
     * @return The nonce prior to increment.
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

    /**
     * @notice Owner can reset any user’s nonce to `newNonce`.
     * @param user The address whose nonce is reset.
     * @param newNonce The value to set.
     */
    function resetNonce(address user, uint256 newNonce) external onlyOwner {
        uint256 old = _nonces[user];
        _nonces[user] = newNonce;
        emit NonceReset(user, old, newNonce);
    }
}
