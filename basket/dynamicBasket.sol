// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title DynamicBasket
/// @notice A contract that represents a dynamic basket of assets where tokens can be added or removed.
contract DynamicBasket {
    address[] public tokens;

    event TokenAdded(address token);
    event TokenRemoved(address token);

    /// @notice Adds a token address to the basket.
    /// @param token The token address to add.
    function addToken(address token) public {
        tokens.push(token);
        emit TokenAdded(token);
    }

    /// @notice Removes a token address from the basket by index.
    /// @param index The index of the token to remove.
    function removeToken(uint256 index) public {
        require(index < tokens.length, "Index out of range");
        address removedToken = tokens[index];
        // Replace the token at the index with the last token and then pop the array.
        tokens[index] = tokens[tokens.length - 1];
        tokens.pop();
        emit TokenRemoved(removedToken);
    }

    /// @notice Retrieves the list of tokens in the basket.
    /// @return An array of token addresses.
    function getTokens() public view returns (address[] memory) {
        return tokens;
    }
}
