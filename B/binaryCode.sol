// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BinaryCode {
    /// @notice Converts a uint256 number to its binary string representation.
    /// @param number The number to convert.
    /// @return A string representing the binary form of the number.
    function toBinary(uint256 number) public pure returns (string memory) {
        if (number == 0) {
            return "0";
        }
        
        // Allocate a temporary bytes array for worst-case 256 bits.
        bytes memory reversed = new bytes(256);
        uint256 i = 0;
        
        // Convert the number to binary by repeatedly dividing by 2.
        while (number != 0) {
            uint256 remainder = number % 2;
            // 48 is ASCII '0' and 49 is ASCII '1'
            reversed[i++] = bytes1(uint8(48 + remainder));
            number = number / 2;
        }
        
        // Create a bytes array for the final result with the exact length.
        bytes memory binaryStr = new bytes(i);
        for (uint256 j = 0; j < i; j++) {
            binaryStr[j] = reversed[i - j - 1]; // Reverse the order.
        }
        
        return string(binaryStr);
    }
}
