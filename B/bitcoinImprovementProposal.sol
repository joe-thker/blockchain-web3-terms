// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BitcoinImprovementProposalDictionary
/// @notice A contract that stores the definition and use cases of Bitcoin Improvement Proposals (BIPs).
contract BitcoinImprovementProposalDictionary {
    // Term for the dictionary entry.
    string public term = "Bitcoin Improvement Proposal (BIP)";
    
    // Definition describing what a BIP is, along with its common use cases.
    string public definition = "A Bitcoin Improvement Proposal (BIP) is a design document used to propose changes or new features to the Bitcoin protocol. It serves as a standard for discussing protocol improvements, technical upgrades, and new functionalities. Use cases include establishing wallet standards (e.g., BIP32), enabling new transaction formats (e.g., BIP141 for SegWit), and guiding overall protocol evolution.";

    /// @notice Retrieves the definition of Bitcoin Improvement Proposal.
    /// @return The definition as a string.
    function getDefinition() public view returns (string memory) {
        return definition;
    }
}
