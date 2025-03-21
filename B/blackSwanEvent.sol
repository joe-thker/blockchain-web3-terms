// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BlackSwanEventDictionary
/// @notice This contract stores and retrieves the definition and use cases for Black Swan Events.
/// @dev A Black Swan Event is an unpredictable, high-impact event; this contract serves as an educational reference.
contract BlackSwanEventDictionary {
    address public owner;
    string public term = "Black Swan Event";
    string public definition;

    event DefinitionUpdated(string newDefinition);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the contract owner and an initial definition.
    constructor() {
        owner = msg.sender;
        definition = "A Black Swan Event is an unpredictable or unforeseen event with severe consequences. In finance, it can lead to dramatic market downturns and systemic disruptions. Use cases include risk management, stress testing, economic research, and designing hedging strategies.";
    }

    /// @notice Retrieves the definition of Black Swan Event.
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
