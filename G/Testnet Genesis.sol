pragma solidity ^0.8.20;

contract TestnetGenesis {
    address public testDeployer;
    string public networkName;

    constructor(string memory _name) {
        testDeployer = msg.sender;
        networkName = _name;
    }
}
