// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TollBridgeModule - Fee-Charging Smart Bridge with Call Enforcement

// ==============================
// 🪙 Toll Token (Fee-Paying ERC20)
// ==============================
contract TollToken {
    string public name = "TollToken";
    string public symbol = "TOLL";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;

    constructor() {
        balances[msg.sender] = 1_000_000 ether;
        totalSupply = balances[msg.sender];
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Low balance");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function burn(address from, uint256 amt) external {
        require(balances[from] >= amt, "Too much");
        balances[from] -= amt;
        totalSupply -= amt;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

// ==============================
// 🌉 Toll Bridge
// ==============================
contract TollBridge {
    TollToken public tollToken;
    uint256 public constant TOLL_FEE = 10 ether;
    address public admin;

    mapping(address => bool) public trustedDestinations;

    event TollPaid(address indexed user, address target, bytes payload);

    constructor(address _tollToken) {
        tollToken = TollToken(_tollToken);
        admin = msg.sender;
    }

    function addTrustedTarget(address target) external {
        require(msg.sender == admin, "Not admin");
        trustedDestinations[target] = true;
    }

    function payTollAndCall(address target, bytes calldata data) external {
        require(trustedDestinations[target], "Untrusted target");
        tollToken.burn(msg.sender, TOLL_FEE);
        (bool success, ) = target.call(data);
        require(success, "Target call failed");
        emit TollPaid(msg.sender, target, data);
    }
}

// ==============================
// 📡 Destination Messenger (Cross-Chain Logic)
// ==============================
contract CrossChainMessenger {
    address public lastCaller;
    string public lastMessage;

    function relay(bytes calldata msgData) external {
        lastCaller = msg.sender;
        lastMessage = string(msgData);
    }
}

// ==============================
// 🔓 Toll Attacker (Fee Bypass Attempt)
// ==============================
interface ITollBridge {
    function payTollAndCall(address, bytes calldata) external;
}

interface ICrossChainMessenger {
    function relay(bytes calldata) external;
}

contract TollAttacker {
    function bypassToll(ICrossChainMessenger target, bytes calldata data) external {
        // Direct call to relay (bypasses bridge toll)
        target.relay(data);
    }

    function tryZeroFee(ITollBridge bridge, address target) external {
        // try calling with empty data (but burns fee anyway)
        bridge.payTollAndCall(target, "");
    }
}
