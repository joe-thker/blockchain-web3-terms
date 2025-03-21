// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BitstreamOperations
/// @notice This contract demonstrates basic bitstream operations such as encoding and decoding booleans,
/// and performing bitwise operations like setting, clearing, and toggling bits.
contract BitstreamOperations {

    /// @notice Encodes an array of booleans into a single uint256 bitstream.
    /// @param bits An array of booleans to encode.
    /// @return bitstream A uint256 representing the encoded bitstream.
    function encodeBooleans(bool[] memory bits) public pure returns (uint256 bitstream) {
        bitstream = 0;
        for (uint256 i = 0; i < bits.length; i++) {
            if (bits[i]) {
                bitstream |= (1 << i);
            }
        }
    }

    /// @notice Decodes a uint256 bitstream back into an array of booleans.
    /// @param bitstream The uint256 bitstream to decode.
    /// @param length The number of bits to decode.
    /// @return bits An array of booleans representing the decoded bitstream.
    function decodeBooleans(uint256 bitstream, uint8 length) public pure returns (bool[] memory bits) {
        bits = new bool[](length);
        for (uint8 i = 0; i < length; i++) {
            bits[i] = ((bitstream >> i) & 1) == 1;
        }
    }

    /// @notice Sets the bit at a given index in the bitstream.
    /// @param bitstream The original bitstream.
    /// @param index The index of the bit to set (0-indexed).
    /// @return The new bitstream with the bit at `index` set to 1.
    function setBit(uint256 bitstream, uint8 index) public pure returns (uint256) {
        require(index < 256, "Index out of range");
        return bitstream | (1 << index);
    }

    /// @notice Clears the bit at a given index in the bitstream.
    /// @param bitstream The original bitstream.
    /// @param index The index of the bit to clear (0-indexed).
    /// @return The new bitstream with the bit at `index` cleared (set to 0).
    function clearBit(uint256 bitstream, uint8 index) public pure returns (uint256) {
        require(index < 256, "Index out of range");
        return bitstream & ~(1 << index);
    }

    /// @notice Toggles the bit at a given index in the bitstream.
    /// @param bitstream The original bitstream.
    /// @param index The index of the bit to toggle (0-indexed).
    /// @return The new bitstream with the bit at `index` toggled.
    function toggleBit(uint256 bitstream, uint8 index) public pure returns (uint256) {
        require(index < 256, "Index out of range");
        return bitstream ^ (1 << index);
    }
}
