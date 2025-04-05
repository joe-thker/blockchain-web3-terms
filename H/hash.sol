pragma solidity ^0.8.20;

contract SimpleHash {
    function hashString(string memory data) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }
}
