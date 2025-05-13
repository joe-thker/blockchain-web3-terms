// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TransactionFeeModule - Native and Protocol-Level Fee Handling with Defense

// ==============================
// 💸 Fee-on-Transfer Token (2% burn on each tx)
// ==============================
contract FeeToken {
    string public name = "FeeToken";
    string public symbol = "FEE";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;

    constructor() {
        balances[msg.sender] = 1_000_000 ether;
        totalSupply = balances[msg.sender];
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        uint256 fee = amt * 2 / 100;
        uint256 net = amt - fee;
        require(balances[msg.sender] >= amt, "Insufficient");

        balances[msg.sender] -= amt;
        balances[to] += net;
        totalSupply -= fee; // burn fee
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

// ==============================
// 🏦 Protocol Fee Vault (charges fixed fee on deposit)
// ==============================
contract ProtocolFeeVault {
    address public feeRecipient;
    uint256 public feeRate = 100; // 1% = 100 basis points
    mapping(address => uint256) public deposits;

    constructor(address _recipient) {
        feeRecipient = _recipient;
    }

    function deposit() external payable {
        uint256 fee = msg.value * feeRate / 10000;
        uint256 net = msg.value - fee;

        deposits[msg.sender] += net;
        payable(feeRecipient).transfer(fee);
    }

    function withdraw() external {
        uint256 amt = deposits[msg.sender];
        require(amt > 0, "Nothing to withdraw");
        deposits[msg.sender] = 0;
        payable(msg.sender).transfer(amt);
    }
}

// ==============================
// 🧾 Meta-Transaction Fee Handler (EIP-2771 style)
// ==============================
contract MetaTXFeeHandler {
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function executeWithFee(
        address to,
        bytes calldata data,
        uint256 fee,
        address token
    ) external {
        require(fee > 0, "No fee");
        require(IERC20(token).transferFrom(msg.sender, admin, fee), "Fee transfer failed");
        (bool ok, ) = to.call(data);
        require(ok, "Execution failed");
    }
}

// ==============================
// 🔓 Fee Attacker (simulate grief or bypass)
// ==============================
interface IFeeToken {
    function transfer(address, uint256) external returns (bool);
}

contract FeeAttacker {
    function spamTransfer(IFeeToken token, address target, uint256 rounds, uint256 amt) external {
        for (uint256 i = 0; i < rounds; i++) {
            token.transfer(target, amt);
        }
    }
}
