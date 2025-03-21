// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BlockchainAsAServiceDictionary
/// @notice A contract that stores and retrieves the definition and use cases for Blockchain as a Service (BaaS).
contract BlockchainAsAServiceDictionary {
    address public owner;
    string public term = "Blockchain as a Service (BaaS)";
    string public definition;

    event DefinitionUpdated(string newDefinition);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the contract owner and an initial definition.
    constructor() {
        owner = msg.sender;
        definition = "Blockchain as a Service (BaaS) is a cloud-based service model that allows users to build, deploy, and manage blockchain-based applications without managing the underlying infrastructure. Use cases include enterprise applications (e.g., supply chain, digital identity), decentralized finance (DeFi), IoT data management, and smart contract development.";
    }

    /// @notice Retrieves the definition of Blockchain as a Service.
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
