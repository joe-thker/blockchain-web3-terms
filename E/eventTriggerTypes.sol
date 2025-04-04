// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EventTriggerTypes {
    address public owner;
    mapping(address => uint256) public balances;

    event BasicEvent(address indexed user, uint256 amount);
    event ConditionalEvent(address indexed user, string message);
    event LoopEvent(address indexed user, uint256 index, uint256 value);
    event FallbackTriggered(address indexed sender, uint256 value);
    event CrossContractEvent(address indexed caller, address target, string data);
    event PreRevertEvent(address indexed user, string reason);

    constructor() {
        owner = msg.sender;
    }

    // 1. Basic Event Trigger
    function deposit() public payable {
        require(msg.value > 0, "Send ETH");
        balances[msg.sender] += msg.value;
        emit BasicEvent(msg.sender, msg.value);
    }

    // 2. Conditional Event Trigger
    function conditionalAction(uint256 amount) external {
        if (amount > 1000 ether) {
            emit ConditionalEvent(msg.sender, "Big spender!");
        } else {
            emit ConditionalEvent(msg.sender, "Small deposit");
        }
    }

    // 3. Loop-Based Event Trigger
    function batchTransfer(address[] calldata recipients, uint256 amount) external payable {
        require(recipients.length > 0, "No recipients");
        require(msg.value == amount * recipients.length, "Incorrect ETH sent");

        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(amount);
            emit LoopEvent(msg.sender, i, amount);
        }
    }

    // 4. Fallback/Receive Trigger
    receive() external payable {
        emit FallbackTriggered(msg.sender, msg.value);
    }

    fallback() external payable {
        emit FallbackTriggered(msg.sender, msg.value);
    }

    // 5. Cross-Contract Event Trigger
    function callExternalHello(address target) external {
        require(target != address(0), "Invalid address");
        (bool success, ) = target.call(abi.encodeWithSignature("hello()"));
        require(success, "External call failed");

        emit CrossContractEvent(msg.sender, target, "hello()");
    }

    // 6. Pre-Revert Trigger
    function simulateFailure(bool shouldFail) external {
        if (shouldFail) {
            emit PreRevertEvent(msg.sender, "Intentional revert for test");
            revert("Simulated failure");
        }
    }
}
