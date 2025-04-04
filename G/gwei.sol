// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GweiTracker {
    struct TxData {
        address sender;
        uint256 gasPriceGwei;
        uint256 valueWei;
        uint256 timestamp;
    }

    TxData[] public txHistory;

    event Received(address indexed from, uint256 value, uint256 gasPriceGwei);

    receive() external payable {
        uint256 gweiPrice = tx.gasprice / 1 gwei;

        txHistory.push(TxData({
            sender: msg.sender,
            gasPriceGwei: gweiPrice,
            valueWei: msg.value,
            timestamp: block.timestamp
        }));

        emit Received(msg.sender, msg.value, gweiPrice);
    }

    function getTx(uint256 index) external view returns (TxData memory) {
        require(index < txHistory.length, "Out of bounds");
        return txHistory[index];
    }

    function convertGweiToWei(uint256 gweiAmount) public pure returns (uint256) {
        return gweiAmount * 1 gwei;
    }

    function convertWeiToGwei(uint256 weiAmount) public pure returns (uint256) {
        return weiAmount / 1 gwei;
    }

    function totalTxs() external view returns (uint256) {
        return txHistory.length;
    }
}
