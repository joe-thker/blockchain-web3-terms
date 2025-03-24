// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DataProvider
/// @notice This contract acts as a simple data provider by storing a string value.
/// Only the owner can update the stored data.
contract DataProvider {
    string private data;
    address public owner;
    
    event DataSet(string newData);

    /// @notice Constructor that sets the initial data and assigns the contract owner.
    /// @param _initialData The initial data to store.
    constructor(string memory _initialData) {
        owner = msg.sender;
        data = _initialData;
    }
    
    /// @notice Updates the stored data.
    /// @param _data The new data to store.
    function setData(string calldata _data) external {
        require(msg.sender == owner, "Only owner can update data");
        data = _data;
        emit DataSet(_data);
    }
    
    /// @notice Retrieves the stored data.
    /// @return The stored data as a string.
    function getData() external view returns (string memory) {
        return data;
    }
}

/// @title FullClient
/// @notice A client contract that interacts with DataProvider with full capabilities: both reading and writing data.
contract FullClient {
    DataProvider public dataProvider;
    address public owner;
    
    event DataUpdated(string newData);
    
    /// @notice Constructor sets the DataProvider address and assigns the client owner.
    /// @param _dataProviderAddress The address of the DataProvider contract.
    constructor(address _dataProviderAddress) {
        owner = msg.sender;
        dataProvider = DataProvider(_dataProviderAddress);
    }
    
    /// @notice Fetches data from the DataProvider.
    /// @return The data retrieved from the provider.
    function fetchData() public view returns (string memory) {
        return dataProvider.getData();
    }
    
    /// @notice Updates data on the DataProvider.
    /// @param _newData The new data to store.
    function updateData(string calldata _newData) public {
        require(msg.sender == owner, "Only owner can update data");
        dataProvider.setData(_newData);
        emit DataUpdated(_newData);
    }
}

/// @title LightClient
/// @notice A client contract that interacts with DataProvider in a read-only manner.
contract LightClient {
    DataProvider public dataProvider;
    
    /// @notice Constructor sets the DataProvider address.
    /// @param _dataProviderAddress The address of the DataProvider contract.
    constructor(address _dataProviderAddress) {
        dataProvider = DataProvider(_dataProviderAddress);
    }
    
    /// @notice Fetches data from the DataProvider.
    /// @return The data retrieved from the provider.
    function fetchData() public view returns (string memory) {
        return dataProvider.getData();
    }
}
