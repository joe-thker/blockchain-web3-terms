// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TradFiModule - Simulates Tokenized TradFi Asset with Bridge, Oracle, and KYC

// ==============================
// 🏦 Custodial TradFi Token
// ==============================
contract CustodialTradFiAsset {
    string public name = "Tokenized Treasury Bond";
    string public symbol = "T-BOND";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public bridge;
    mapping(address => uint256) public balances;

    modifier onlyBridge() {
        require(msg.sender == bridge, "Not bridge");
        _;
    }

    constructor(address _bridge) {
        bridge = _bridge;
    }

    function mint(address to, uint256 amt) external onlyBridge {
        balances[to] += amt;
        totalSupply += amt;
    }

    function burn(address from, uint256 amt) external onlyBridge {
        require(balances[from] >= amt, "Too much");
        balances[from] -= amt;
        totalSupply -= amt;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Low");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

// ==============================
// 🌉 TradFi Asset Bridge (Off-chain Triggered)
// ==============================
contract TradFiBridge {
    CustodialTradFiAsset public token;
    address public admin;

    constructor(address _token) {
        token = CustodialTradFiAsset(_token);
        admin = msg.sender;
    }

    function depositToChain(address user, uint256 amt) external {
        require(msg.sender == admin, "Not admin");
        token.mint(user, amt); // simulate TradFi custody deposit
    }

    function withdrawFromChain(address user, uint256 amt) external {
        require(msg.sender == admin, "Not admin");
        token.burn(user, amt); // simulate withdrawal to TradFi custodian
    }
}

// ==============================
// 🧾 ZK-KYC Verifier (Simulated)
// ==============================
contract ZKKYCVerifier {
    mapping(address => bool) public verified;

    function submitProof(address user, bytes calldata zkProof) external {
        // In practice, this verifies zk-SNARKs or Semaphore proofs
        require(zkProof.length > 0, "Invalid proof");
        verified[user] = true;
    }

    function isVerified(address user) external view returns (bool) {
        return verified[user];
    }
}

// ==============================
// 🔓 TradFi Attacker (Mint or Bridge Bypass)
// ==============================
interface ITradFiToken {
    function mint(address, uint256) external;
}

contract TradFiAttacker {
    function tryUnauthorizedMint(ITradFiToken token, address victim, uint256 amt) external {
        token.mint(victim, amt); // should fail if caller not bridge
    }
}
