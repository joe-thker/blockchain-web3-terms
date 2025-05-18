// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title WindingUpVault - Activates once and locks configuration to production state
contract WindingUpVault {
    address public immutable deployer;
    address public treasury;
    bool public isWoundUp;

    uint256 public totalDeposited;

    event VaultWoundUp(address treasury);
    event Deposited(address indexed user, uint256 amount);

    constructor() {
        deployer = msg.sender;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Not deployer");
        _;
    }

    modifier onlyWhenReady() {
        require(isWoundUp, "Vault not active yet");
        _;
    }

    function windUp(address _treasury) external onlyDeployer {
        require(!isWoundUp, "Already wound up");
        require(_treasury != address(0), "Invalid treasury");
        treasury = _treasury;
        isWoundUp = true;
        emit VaultWoundUp(_treasury);
    }

    function deposit() external payable onlyWhenReady {
        require(msg.value > 0, "Zero deposit");
        totalDeposited += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdrawAll() external onlyDeployer {
        require(isWoundUp, "Vault must be active");
        (bool ok, ) = treasury.call{value: address(this).balance}("");
        require(ok, "Withdraw failed");
    }

    receive() external payable {}
}
