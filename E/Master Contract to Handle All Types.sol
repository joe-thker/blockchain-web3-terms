// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ---------------- INTERFACES ----------------

interface IOtherContract {
    function hello() external;
}

interface IDeployedContract {
    function greeting() external view returns (string memory);
}

// ---------------- CONTRACT ------------------

contract EthereumTransactionTypes {
    event ETHTransferred(address indexed from, address indexed to, uint256 amount);
    event ContractCalled(address indexed from, string message);
    event ContractDeployed(address contractAddress);
    event DelegateCalled(address from, address target);
    event InternalTxTriggered(address from, address to);
    event ForceTransferReceived(address from, uint256 amount);

    // ========== 1. ETH Transfer ==========
    function sendETH(address payable recipient) external payable {
        require(msg.value > 0, "Send some ETH");
        (bool sent, ) = recipient.call{value: msg.value}("");
        require(sent, "Failed to send ETH");
        emit ETHTransferred(msg.sender, recipient, msg.value);
    }

    // ========== 2. Contract Call ==========
    function callOtherContract(address target) external {
        IOtherContract(target).hello();
        emit ContractCalled(msg.sender, "Called hello() on other contract");
    }

    // ========== 3. Contract Deployment ==========
    function deployNewContract() external {
        DeployedContract newContract = new DeployedContract();
        emit ContractDeployed(address(newContract));
    }

    // ========== 4. Delegatecall ==========
    function delegateTo(address implementation) external {
        (bool success, ) = implementation.delegatecall(
            abi.encodeWithSignature("logDelegateCall()")
        );
        require(success, "Delegatecall failed");
        emit DelegateCalled(msg.sender, implementation);
    }

    // ========== 5. Internal Transaction ==========
    function triggerInternalTransaction(address target) external {
        InternalCaller(target).internalCall(msg.sender);
        emit InternalTxTriggered(msg.sender, target);
    }

    // ========== 6. Self-Destruct Transfer ==========
    function deployAndSelfDestruct(address payable target) external payable {
        require(msg.value > 0, "Send ETH");
        SelfDestructSender sender = new SelfDestructSender{value: msg.value}(target);
        sender.destroyAndSend();
    }

    receive() external payable {
        emit ForceTransferReceived(msg.sender, msg.value);
    }
}

// ---------------- SUPPORTING CONTRACTS ----------------

contract DeployedContract {
    string public greeting = "I am alive!";
}

contract InternalCaller {
    event InternalHello(address user);

    function internalCall(address user) external {
        sayHello(user);
    }

    function sayHello(address user) internal {
        emit InternalHello(user);
    }
}

contract DelegateTarget {
    address public sender;
    string public message;

    function logDelegateCall() external {
        sender = msg.sender;
        message = "Delegatecall worked";
    }
}

contract SelfDestructSender {
    constructor(address payable) payable {}

    function destroyAndSend() external {
        selfdestruct(payable(msg.sender));
    }
}
