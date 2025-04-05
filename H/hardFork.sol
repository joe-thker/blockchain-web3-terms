// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TokenV1 {
    string public name = "HardForkedToken";
    mapping(address => uint256) public balances;

    function mint() external {
        balances[msg.sender] += 100;
    }

    function getVersion() external pure returns (string memory) {
        return "V1";
    }
}
