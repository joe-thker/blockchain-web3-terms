// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title WhiteSwanNotifier - Emits onchain events to mark positive predictable events
contract WhiteSwanNotifier {
    address public immutable admin;

    event WhiteSwanAnnounced(string title, string description, uint256 activationTime);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    function announce(string calldata title, string calldata description, uint256 activationTime) external onlyAdmin {
        emit WhiteSwanAnnounced(title, description, activationTime);
    }
}
