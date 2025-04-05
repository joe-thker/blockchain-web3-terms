pragma solidity ^0.8.20;

contract KeccakExample {
    function hash(string memory input) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(input));
    }
}
