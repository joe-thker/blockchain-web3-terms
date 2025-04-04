// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EventTriggerExample {
    mapping(address => uint256) public balances;
    address public owner;

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event CustomAction(address indexed user, string action, uint256 value);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // ========== 1. Deposit ETH and trigger event ==========
    function deposit() public payable {
        require(msg.value > 0, "Send some ETH");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // ========== 2. Withdraw and trigger event ==========
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Withdraw failed");

        emit Withdrawn(msg.sender, amount);
    }

    // ========== 3. Ownership Transfer Trigger ==========
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // ========== 4. Custom Event Action ==========
    function performAction(string calldata action, uint256 value) external {
        emit CustomAction(msg.sender, action, value);
    }

    // ========== 5. Receive ETH and trigger deposit event ==========
    receive() external payable {
        deposit();
    }
}
