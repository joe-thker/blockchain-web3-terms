// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ConfirmedTxOracleBridge {
    address public trustedOracle;

    mapping(bytes32 => bool) public confirmedTx;

    event ConfirmedProcessed(bytes32 txHash, address indexed user, uint256 value);

    constructor(address _oracle) {
        trustedOracle = _oracle;
    }

    function reportConfirmedTx(bytes32 txHash, address user, uint256 value) external {
        require(msg.sender == trustedOracle, "Not authorized");
        require(!confirmedTx[txHash], "Already processed");

        confirmedTx[txHash] = true;

        // Example: mint tokens, unlock funds, etc.
        emit ConfirmedProcessed(txHash, user, value);
    }
}
