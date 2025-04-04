pragma solidity ^0.8.20;

contract DAOGenesis {
    address public creator;
    address[] public council;

    constructor(address[] memory _founders) {
        creator = msg.sender;
        council = _founders;
    }

    function getFounders() external view returns (address[] memory) {
        return council;
    }
}
