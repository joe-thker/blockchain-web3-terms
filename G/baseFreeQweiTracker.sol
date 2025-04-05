pragma solidity ^0.8.20;

contract BaseFeeGwei {
    function getBaseFeeGwei() external view returns (uint256) {
        return block.basefee / 1 gwei;
    }
}
