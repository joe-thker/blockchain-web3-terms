// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BullMarketDictionary
/// @notice This contract stores and retrieves the definition and use cases of a Bull Market.
contract BullMarketDictionary {
    address public owner;
    string public term = "Bull Market";
    string public definition;

    event DefinitionUpdated(string newDefinition);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the deployer as the owner and initializes the definition.
    constructor() {
        owner = msg.sender;
        definition = "A Bull Market is a market condition where asset prices are rising or expected to rise, driven by investor confidence and sustained buying pressure. Use cases include investment strategy development, market analysis, portfolio management, and influencing risk appetite.";
    }

    /// @notice Retrieves the definition of Bull Market.
    /// @return The definition as a string.
    function getDefinition() public view returns (string memory) {
        return definition;
    }

    /// @notice Allows the owner to update the definition.
    /// @param newDefinition The new definition string.
    function updateDefinition(string memory newDefinition) public onlyOwner {
        definition = newDefinition;
        emit DefinitionUpdated(newDefinition);
    }
}
