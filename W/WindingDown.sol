// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title WindingDownVault - Securely winds down a protocol and releases funds
contract WindingDownVault {
    address public immutable admin;
    bool public isWindingDown;
    uint256 public shutdownTimestamp;

    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event ShutdownStarted(uint256 timestamp);

    constructor() {
        admin = msg.sender;
    }

    modifier notShutdown() {
        require(!isWindingDown, "Vault is winding down");
        _;
    }

    function deposit() external payable notShutdown {
        require(msg.value > 0, "No deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amt = balances[msg.sender];
        require(amt > 0, "Nothing to withdraw");

        balances[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: amt}("");
        require(ok, "Withdraw failed");

        emit Withdrawn(msg.sender, amt);
    }

    function startShutdown() external {
        require(msg.sender == admin, "Not admin");
        require(!isWindingDown, "Already shutting down");
        isWindingDown = true;
        shutdownTimestamp = block.timestamp;
        emit ShutdownStarted(block.timestamp);
    }

    function recoverRemaining() external {
        require(isWindingDown, "Not shutting down");
        require(block.timestamp >= shutdownTimestamp + 30 days, "Grace period active");
        require(msg.sender == admin, "Not admin");

        (bool ok, ) = admin.call{value: address(this).balance}("");
        require(ok, "Recover failed");
    }

    receive() external payable {}
}
