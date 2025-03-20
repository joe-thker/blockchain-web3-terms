// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BearWhaleDictionary
/// @notice A contract to store and retrieve the definition of "Bear Whale" in the crypto context.
contract BearWhaleDictionary {
    // Term and definition stored as public variables.
    string public term = "Bear Whale";
    string public definition = "In crypto, a 'Bear Whale' refers to a large holder of cryptocurrency who is bearish on the market. Such an entity can sell significant amounts of tokens to drive prices down, influencing market sentiment and potentially triggering panic selling or forced liquidations.";

    /// @notice Retrieves the definition of Bear Whale.
    /// @return The definition as a string.
    function getDefinition() public view returns (string memory) {
        return definition;
    }
}
