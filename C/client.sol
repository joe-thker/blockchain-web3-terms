// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DataProvider
/// @notice This contract stores a message that can be updated and retrieved.
contract DataProvider {
    string private message;

    event MessageUpdated(string newMessage);

    /// @notice Constructor sets the initial message.
    /// @param _initialMessage The message to initialize.
    constructor(string memory _initialMessage) {
        message = _initialMessage;
    }

    /// @notice Updates the stored message.
    /// @param _newMessage The new message to store.
    function setMessage(string memory _newMessage) public {
        message = _newMessage;
        emit MessageUpdated(_newMessage);
    }

    /// @notice Retrieves the current stored message.
    /// @return The stored message.
    function getMessage() public view returns (string memory) {
        return message;
    }
}

/// @title Client
/// @notice This contract simulates a client that interacts with the DataProvider contract.
/// It fetches the stored message from the DataProvider and can also update its reference.
contract Client {
    DataProvider public dataProvider;

    event ProviderUpdated(address newProvider);

    /// @notice Constructor sets the initial DataProvider contract address.
    /// @param _dataProviderAddress The address of the DataProvider contract.
    constructor(address _dataProviderAddress) {
        dataProvider = DataProvider(_dataProviderAddress);
    }

    /// @notice Fetches the message from the DataProvider.
    /// @return The message retrieved from the provider.
    function fetchMessage() public view returns (string memory) {
        return dataProvider.getMessage();
    }

    /// @notice Updates the DataProvider contract reference.
    /// @param _newProviderAddress The new DataProvider contract address.
    function updateDataProvider(address _newProviderAddress) public {
        dataProvider = DataProvider(_newProviderAddress);
        emit ProviderUpdated(_newProviderAddress);
    }
}
