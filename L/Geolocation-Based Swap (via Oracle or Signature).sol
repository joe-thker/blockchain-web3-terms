// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title GeoSwap via Oracle Signature
/// @notice Users must present a signed message from oracle confirming location presence
contract GeoSwap {
    using ECDSA for bytes32;

    address public oracle;
    mapping(address => bool) public allowed;

    event Swapped(address indexed user, uint256 amount);

    constructor(address _oracle) {
        oracle = _oracle;
    }

    /// @notice Verifies location via oracle-signed message
    function verifyLocation(address user, bytes calldata signature) external {
        bytes32 messageHash = keccak256(abi.encodePacked(user, "LATLONG:XYZ"));
        bytes32 ethSignedHash = messageHash.toEthSignedMessageHash();
        address signer = ethSignedHash.recover(signature);
        require(signer == oracle, "Invalid location proof");
        allowed[user] = true;
    }

    /// @notice Allows location-verified users to perform a location-locked swap
    function locationSwap() external payable {
        require(allowed[msg.sender], "Not geo-verified");
        emit Swapped(msg.sender, msg.value);
    }
}
