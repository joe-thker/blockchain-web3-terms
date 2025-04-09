// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Anti-LARP Reputation Registry
contract AntiLarpRegistry {
    mapping(address => bool) public isVerifiedBuilder;
    mapping(address => bool) public isFlaggedLARP;
    address public admin;

    event Verified(address indexed user);
    event FlaggedLARP(address indexed user);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function verifyBuilder(address user) external onlyAdmin {
        isVerifiedBuilder[user] = true;
        emit Verified(user);
    }

    function flagAsLARP(address user) external onlyAdmin {
        isFlaggedLARP[user] = true;
        emit FlaggedLARP(user);
    }

    function isLARP(address user) external view returns (bool) {
        return isFlaggedLARP[user] && !isVerifiedBuilder[user];
    }
}
