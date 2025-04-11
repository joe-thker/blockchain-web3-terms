// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract MainnetCheck {
    uint256 constant ETH_MAINNET_CHAINID = 1;

    function isMainnet() public view returns (bool) {
        return block.chainid == ETH_MAINNET_CHAINID;
    }

    function mainnetOnlyAction() external view returns (string memory) {
        require(isMainnet(), "Not on mainnet");
        return "This logic only runs on Ethereum mainnet!";
    }
}
