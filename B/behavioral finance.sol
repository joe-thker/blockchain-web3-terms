// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BehavioralFinanceDictionary
/// @notice A contract that stores the definition and use cases of Behavioral Finance.
contract BehavioralFinanceDictionary {
    // The term and its definition
    string public term = "Behavioral Finance";
    string public definition = "Behavioral Finance is a field of study that combines psychology and economics to explain investor behavior in markets. It investigates how cognitive biases, emotions, and social influences can lead to irrational decision-making, market anomalies, and deviations from traditional financial models. Use cases include explaining market overreactions, designing better investment strategies, risk management, and investor education.";

    /// @notice Retrieves the definition of Behavioral Finance.
    /// @return The definition as a string.
    function getDefinition() public view returns (string memory) {
        return definition;
    }
}
