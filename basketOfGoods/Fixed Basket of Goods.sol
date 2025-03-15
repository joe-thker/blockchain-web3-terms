// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title FixedBasketOfGoods
/// @notice A contract representing a fixed basket of goods that is set at deployment.
contract FixedBasketOfGoods {
    // Array to store the list of goods.
    string[] public goods;

    /// @notice Constructor to initialize the fixed basket of goods.
    /// @param _goods The array of goods to be stored in the basket.
    constructor(string[] memory _goods) {
        goods = _goods;
    }

    /// @notice Retrieves the list of goods in the basket.
    /// @return An array of goods.
    function getGoods() public view returns (string[] memory) {
        return goods;
    }
}
