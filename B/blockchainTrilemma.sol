// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BlockchainTrilemmaDictionary
/// @notice A contract that stores and retrieves information about the blockchain trilemma.
contract BlockchainTrilemmaDictionary {
    address public owner;
    string public term = "Blockchain Trilemma";
    string public definition;

    event DefinitionUpdated(string newDefinition);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the contract owner and an initial definition of the blockchain trilemma.
    constructor() {
        owner = msg.sender;
        definition = "The blockchain trilemma is the challenge of balancing decentralization, scalability, and security in blockchain design. Enhancing one or two often comes at the expense of the third, leading to trade-offs in network design.";
    }

    /// @notice Retrieves the definition of the blockchain trilemma.
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
