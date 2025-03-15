// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title FixedBasket
/// @notice A contract that represents a fixed basket of assets.
contract FixedBasket {
    // Array of token addresses that constitute the basket.
    address[] public tokens;

    /// @notice Constructor to initialize the basket with a fixed set of token addresses.
    /// @param _tokens The addresses of the tokens to include in the basket.
    constructor(address[] memory _tokens) {
        tokens = _tokens;
    }

    /// @notice Retrieves the list of tokens in the basket.
    /// @return An array of token addresses.
    function getTokens() public view returns (address[] memory) {
        return tokens;
    }
}
