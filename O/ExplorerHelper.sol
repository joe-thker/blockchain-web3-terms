// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ExplorerHelper
 * @notice Constructs FTMScan URLs for Opera transaction hashes & addresses.
 */
contract ExplorerHelper {
    string public constant BASE = "https://ftmscan.com";

    /// @notice URL to view a transaction on FTMScan
    function txUrl(bytes32 txHash) external pure returns (string memory) {
        return string.concat(BASE, "/tx/", _toHexString(txHash));
    }

    /// @notice URL to view an address on FTMScan
    function addrUrl(address account) external pure returns (string memory) {
        return string.concat(BASE, "/address/", _toHexString(keccak256(abi.encodePacked(account))));
    }

    function _toHexString(bytes32 data) private pure returns (string memory) {
        bytes16 hexSymbols = "0123456789abcdef";
        bytes memory buf = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            buf[2*i]   = hexSymbols[uint8(data[i] >> 4)];
            buf[2*i+1] = hexSymbols[uint8(data[i] & 0x0f)];
        }
        return string(abi.encodePacked("0x", buf));
    }
}
