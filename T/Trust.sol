// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TrustModule - Demonstrates different trust assumptions in smart contracts

/// 🧨 TrustedVault (Centralized Owner - Risky)
contract TrustedVault {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function adminWithdraw(address to, uint256 amt) external {
        require(msg.sender == owner, "Not owner");
        payable(to).transfer(amt);
    }
}

/// ✅ TrustlessVault (No Admin, Immutable)
contract TrustlessVault {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amt) external {
        require(balances[msg.sender] >= amt, "Too much");
        balances[msg.sender] -= amt;
        payable(msg.sender).transfer(amt);
    }
}

/// 🛡️ MultisigTrustVault (Shared Trust)
contract MultisigTrustVault {
    address[] public signers;
    mapping(bytes32 => bool) public approved;
    mapping(address => uint256) public balances;

    constructor(address[] memory _signers) {
        signers = _signers;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function execute(address to, uint256 amt, bytes32 txId, bytes[] calldata sigs) external {
        require(!approved[txId], "Already approved");
        require(_validateSignatures(txId, sigs), "Invalid sigs");
        approved[txId] = true;
        payable(to).transfer(amt);
    }

    function _validateSignatures(bytes32 txId, bytes[] calldata sigs) internal view returns (bool) {
        uint256 valid;
        for (uint256 i = 0; i < sigs.length; i++) {
            address signer = recover(txId, sigs[i]);
            for (uint256 j = 0; j < signers.length; j++) {
                if (signers[j] == signer) {
                    valid++;
                    break;
                }
            }
        }
        return valid >= 2; // 2-of-N multisig
    }

    function recover(bytes32 h, bytes memory sig) internal pure returns (address) {
        bytes32 m = prefixed(h);
        (uint8 v, bytes32 r, bytes32 s) = split(sig);
        return ecrecover(m, v, r, s);
    }

    function prefixed(bytes32 h) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }

    function split(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "Invalid sig");
        bytes32 r; bytes32 s; uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }
}

/// 📡 OracleTrustVault (Relies on External Oracle)
interface IOracle {
    function getPrice() external view returns (uint256);
}

contract OracleTrustVault {
    IOracle public priceFeed;
    mapping(address => uint256) public balances;

    constructor(address _oracle) {
        priceFeed = IOracle(_oracle);
    }

    function deposit() external payable {
        require(priceFeed.getPrice() > 1000, "Price too low"); // Require trust in data
        balances[msg.sender] += msg.value;
    }
}
