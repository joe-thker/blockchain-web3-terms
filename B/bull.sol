// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BullDictionary
/// @notice This contract stores and retrieves a definition for the term "Bull" in the cryptocurrency context.
contract BullDictionary {
    address public owner;
    string public term = "Bull";
    string public definition;

    event DefinitionUpdated(string newDefinition);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the deployer as the owner and initializes the definition.
    constructor() {
        owner = msg.sender;
        definition = "A 'Bull' in crypto refers to an investor who is optimistic about market trends, expecting asset prices to rise. Bullish sentiment typically drives increased buying pressure, supporting upward price movements.";
    }

    /// @notice Retrieves the current definition of 'Bull'.
    /// @return The definition as a string.
    function getDefinition() public view returns (string memory) {
        return definition;
    }

    /// @notice Allows the owner to update the definition of 'Bull'.
    /// @param newDefinition The new definition string.
    function updateDefinition(string memory newDefinition) public onlyOwner {
        definition = newDefinition;
        emit DefinitionUpdated(newDefinition);
    }
}
