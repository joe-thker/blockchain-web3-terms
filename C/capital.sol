// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CapitalDictionary
/// @notice A contract that stores and retrieves the definition and use cases for the term "Capital" in finance and crypto.
contract CapitalDictionary {
    address public owner;
    string public term = "Capital";
    string public definition;

    event DefinitionUpdated(string newDefinition);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the deployer as the owner and initializes the definition.
    constructor() {
        owner = msg.sender;
        definition = "Capital refers to the financial resources available for investment or operational purposes. In crypto, capital includes cryptocurrencies, tokens, and fiat-backed digital assets that are used for trading, liquidity provision, and project funding. It is essential for generating returns, managing risk, and fueling innovation in both traditional and decentralized finance.";
    }

    /// @notice Retrieves the definition of Capital.
    /// @return The current definition as a string.
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
