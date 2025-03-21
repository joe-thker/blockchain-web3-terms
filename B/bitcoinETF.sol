// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BitcoinETFDictionary
/// @notice A simple contract that stores the definition and key aspects of a Bitcoin ETF.
contract BitcoinETFDictionary {
    // The term "Bitcoin ETF"
    string public term = "Bitcoin ETF";
    
    // The definition string explaining what a Bitcoin ETF is, its use cases, and its main types.
    string public definition = "A Bitcoin ETF is an exchange-traded fund that tracks the price of Bitcoin, allowing investors to gain exposure without directly holding the cryptocurrency. There are primarily two types: physically-backed ETFs, which hold actual Bitcoin, and futures-based ETFs, which invest in Bitcoin futures contracts. Use cases include regulated exposure to Bitcoin, portfolio diversification, ease of trading, hedging, and speculation.";
    
    /// @notice Retrieves the definition of Bitcoin ETF.
    /// @return The definition as a string.
    function getDefinition() public view returns (string memory) {
        return definition;
    }
}
