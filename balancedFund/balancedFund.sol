// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title TermsDictionary
/// @notice A contract to store and retrieve various financial, technical, and economic terms along with their definitions.
contract TermsDictionary {
    // Mapping from a term (string) to its definition (string)
    mapping(string => string) private terms;

    // Event emitted when a term is added or updated.
    event TermAddedOrUpdated(string term, string definition);

    /// @notice Constructor to initialize some common terms.
    constructor() {
        // Initial terms and definitions.
        terms["Blockchain"] = "A decentralized digital ledger that records transactions across multiple computers.";
        terms["Smart Contract"] = "Self-executing code with the terms of the agreement directly written into the blockchain.";
        terms["Balanced Fund"] = "An investment fund that holds a diversified mix of asset classes, typically including both equities and fixed income securities, to achieve a balance between growth and income while managing risk through diversification.";

        // Emit events for each term added.
        emit TermAddedOrUpdated("Blockchain", terms["Blockchain"]);
        emit TermAddedOrUpdated("Smart Contract", terms["Smart Contract"]);
        emit TermAddedOrUpdated("Balanced Fund", terms["Balanced Fund"]);
    }

    /// @notice Adds or updates a term with its definition.
    /// @param _term The term to add or update.
    /// @param _definition The definition of the term.
    function addOrUpdateTerm(string memory _term, string memory _definition) public {
        terms[_term] = _definition;
        emit TermAddedOrUpdated(_term, _definition);
    }

    /// @notice Retrieves the definition of a given term.
    /// @param _term The term to retrieve the definition for.
    /// @return The definition associated with the term.
    function getDefinition(string memory _term) public view returns (string memory) {
        require(bytes(terms[_term]).length > 0, "Term not found");
        return terms[_term];
    }
}
