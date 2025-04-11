// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FeatureForkUpgradeable {
    address public owner;
    uint8 public version;

    constructor() {
        owner = msg.sender;
        version = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function upgradeVersion(uint8 newVersion) external onlyOwner {
        require(newVersion > version, "Must upgrade forward");
        version = newVersion;
    }

    function runFeature() public view returns (string memory) {
        if (version == 1) return "Running Feature v1";
        if (version == 2) return "Running Feature v2 (Fork)";
        return "Unknown version";
    }
}
