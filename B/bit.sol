// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BitOperations
/// @notice A contract demonstrating various bitwise operations on a uint256 value.
contract BitOperations {
    
    /// @notice Checks if the bit at a given index is set (1) in the number.
    /// @param number The number to check.
    /// @param bitIndex The index of the bit (0-indexed, must be less than 256).
    /// @return True if the bit is set, false otherwise.
    function isBitSet(uint256 number, uint8 bitIndex) public pure returns (bool) {
        require(bitIndex < 256, "Bit index out of range");
        return (number & (1 << bitIndex)) != 0;
    }

    /// @notice Sets the bit at a given index to 1.
    /// @param number The original number.
    /// @param bitIndex The index of the bit to set (0-indexed).
    /// @return The new number with the bit at bitIndex set.
    function setBit(uint256 number, uint8 bitIndex) public pure returns (uint256) {
        require(bitIndex < 256, "Bit index out of range");
        return number | (1 << bitIndex);
    }

    /// @notice Clears the bit at a given index (sets it to 0).
    /// @param number The original number.
    /// @param bitIndex The index of the bit to clear (0-indexed).
    /// @return The new number with the bit at bitIndex cleared.
    function clearBit(uint256 number, uint8 bitIndex) public pure returns (uint256) {
        require(bitIndex < 256, "Bit index out of range");
        return number & ~(1 << bitIndex);
    }

    /// @notice Toggles the bit at a given index.
    /// @param number The original number.
    /// @param bitIndex The index of the bit to toggle (0-indexed).
    /// @return The new number with the bit at bitIndex toggled.
    function toggleBit(uint256 number, uint8 bitIndex) public pure returns (uint256) {
        require(bitIndex < 256, "Bit index out of range");
        return number ^ (1 << bitIndex);
    }

    /// @notice Counts the number of bits set to 1 in the given number.
    /// @param number The number to evaluate.
    /// @return count The count of bits set to 1.
    function countSetBits(uint256 number) public pure returns (uint8 count) {
        while (number != 0) {
            count++;
            number &= (number - 1); // Clear the least significant bit set
        }
    }
}
