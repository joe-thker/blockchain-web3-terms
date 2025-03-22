// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BruteForceChallenge
/// @notice This contract holds a secret (as a hash) and allows users to guess it.
/// If a correct guess is provided, the contract records the winner.
contract BruteForceChallenge {
    bytes32 private secretHash;
    address public winner;

    /// @notice The constructor initializes the challenge with a secret.
    /// @param secret The secret number to be guessed.
    constructor(uint256 secret) {
        secretHash = keccak256(abi.encodePacked(secret));
    }

    /// @notice Allows a user to submit a guess.
    /// @param _guess The guess provided by the user.
    /// @return True if the guess is correct, false otherwise.
    function guess(uint256 _guess) public returns (bool) {
        if (keccak256(abi.encodePacked(_guess)) == secretHash) {
            winner = msg.sender;
            return true;
        } else {
            return false;
        }
    }

    /// @notice (For testing only) Returns the stored hash of the secret.
    /// @return The hash of the secret.
    function getSecretHash() public view returns (bytes32) {
        return secretHash;
    }
}

/// @title BruteForceAttacker
/// @notice This contract demonstrates a brute force attack by trying all numbers in a given range.
/// @dev This is for educational purposes. Real brute force loops are limited by gas constraints.
contract BruteForceAttacker {
    /// @notice Attempts to brute force the secret in the challenge contract over a specified range.
    /// @param challengeAddress The address of the BruteForceChallenge contract.
    /// @param start The starting number for the brute force attempt.
    /// @param end The ending number for the brute force attempt.
    /// @return correctGuess The value that correctly satisfies the challenge.
    function attack(address challengeAddress, uint256 start, uint256 end) public returns (uint256 correctGuess) {
        for (uint256 i = start; i <= end; i++) {
            // Using a low-level call to interact with the guess() function.
            (bool success, bytes memory data) = challengeAddress.call(
                abi.encodeWithSignature("guess(uint256)", i)
            );
            if (success && data.length >= 32) {
                bool result = abi.decode(data, (bool));
                if (result) {
                    return i;
                }
            }
        }
        revert("No valid guess found in the given range");
    }
}
