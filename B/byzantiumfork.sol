// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ByzantiumForkDictionary
/// @notice This contract stores and retrieves the definition and use cases for the Byzantium Fork.
contract ByzantiumForkDictionary {
    address public owner;
    string public term = "Byzantium Fork";
    string public definition;

    event DefinitionUpdated(string newDefinition);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the deployer as the owner and initializes the definition.
    constructor() {
        owner = msg.sender;
        definition = "The Byzantium Fork was a major Ethereum network upgrade implemented in October 2017 that improved security, privacy, and scalability. It optimized the EVM, reduced gas costs, and enhanced smart contract efficiency. This fork paved the way for future upgrades and increased the overall robustness of the network. Its improvements have helped decentralized applications run more efficiently and securely. Use cases include enhanced network performance, cost-effective contract execution, and increased security for the Ethereum ecosystem.";
    }

    /// @notice Retrieves the definition of the Byzantium Fork.
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
