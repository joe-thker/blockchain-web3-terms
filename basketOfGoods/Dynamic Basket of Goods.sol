// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title DynamicBasketOfGoods
/// @notice A contract representing a dynamic basket of goods where items can be added or removed.
contract DynamicBasketOfGoods {
    // Array to store the list of goods.
    string[] public goods;

    // Events for adding and removing goods.
    event GoodAdded(string good);
    event GoodRemoved(string good);

    /// @notice Adds a new good to the basket.
    /// @param _good The name or identifier of the good to add.
    function addGood(string memory _good) public {
        goods.push(_good);
        emit GoodAdded(_good);
    }

    /// @notice Removes a good from the basket by index.
    /// @param index The index of the good to remove.
    function removeGood(uint256 index) public {
        require(index < goods.length, "Index out of range");
        string memory removedGood = goods[index];
        // Replace the removed good with the last good and then pop the array.
        goods[index] = goods[goods.length - 1];
        goods.pop();
        emit GoodRemoved(removedGood);
    }

    /// @notice Retrieves the list of goods in the basket.
    /// @return An array of goods.
    function getGoods() public view returns (string[] memory) {
        return goods;
    }
}
