// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ContextualNonce
 * @notice Tracks a nonce per (contextId, user) key.
 *         - getNonce(ctx, user)  
 *         - useNonce(ctx) for msg.sender  
 *         - incrementNonce(ctx)
 */
contract ContextualNonce {
    // contextId → user → nonce
    mapping(bytes32 => mapping(address => uint256)) private _nonces;

    event ContextNonceUsed(bytes32 indexed context, address indexed user, uint256 oldNonce, uint256 newNonce);

    /// @notice View the nonce for a given context & user.
    function getNonce(bytes32 context, address user) external view returns (uint256) {
        return _nonces[context][user];
    }

    /**
     * @notice Consume & return msg.sender’s nonce for `context`, then increment.
     * @param context The context identifier.
     */
    function useNonce(bytes32 context) external returns (uint256) {
        uint256 current = _nonces[context][msg.sender];
        _nonces[context][msg.sender] = current + 1;
        emit ContextNonceUsed(context, msg.sender, current, current + 1);
        return current;
    }

    /// @notice Increment msg.sender’s nonce for `context` without returning it.
    function incrementNonce(bytes32 context) external {
        uint256 current = _nonces[context][msg.sender];
        _nonces[context][msg.sender] = current + 1;
        emit ContextNonceUsed(context, msg.sender, current, current + 1);
    }
}
