// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ForkChoiceOracleDriven {
    address public oracle;
    bytes32 public chosenFork;

    event ForkChosen(bytes32 indexed forkId);

    constructor(address _oracle) {
        oracle = _oracle;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "Not oracle");
        _;
    }

    function setFork(bytes32 forkId) external onlyOracle {
        chosenFork = forkId;
        emit ForkChosen(forkId);
    }

    function getCanonical() external view returns (bytes32) {
        return chosenFork;
    }
}
