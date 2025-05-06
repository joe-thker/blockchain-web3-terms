// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title LibraryPatternsSuite
/// @notice Demonstrates insecure vs. secure uses of common Solidity libraries

// Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

//////////////////////////////////////////////////////
// 1) Math Library
//////////////////////////////////////////////////////
library InsecureMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked { return a + b; }  // overflow wraps
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked { return a * b; }  // overflow wraps
    }
}

contract MathUser is ReentrancyGuard {
    using InsecureMath for uint256;

    uint256 public totalInsecure;
    uint256 public totalSecure;

    // --- Attack: overflowable
    function accumulateInsecure(uint256 x) external {
        totalInsecure = totalInsecure.add(x);
    }

    // --- Defense: built-in checked arithmetic
    function accumulateSecure(uint256 x) external {
        totalSecure += x;  // Solidity ≥0.8 auto-checks overflow
    }
}

//////////////////////////////////////////////////////
// 2) ECDSA Library
//////////////////////////////////////////////////////
library InsecureECDSA {
    function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        // naïve: no malleability guard
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(sig, (bytes32,bytes32,uint8));
        return ecrecover(hash, v, r, s);
    }
}

library SecureECDSA {
    // enforces s in lower half order per EIP-2: s <= secp256k1n/2
    function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(sig, (bytes32,bytes32,uint8));
        // secp256k1n/2:
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
                "ECDSA: invalid S");
        return ecrecover(hash, v, r, s);
    }
}

contract ECDSAUser {
    using InsecureECDSA for bytes32;
    using SecureECDSA   for bytes32;

    // --- Attack: accepts malleable sigs
    function verifyInsecure(bytes32 hash, bytes calldata sig, address signer) external pure returns (bool) {
        return hash.recover(sig) == signer;
    }

    // --- Defense: rejects high-S malleable sigs
    function verifySecure(bytes32 hash, bytes calldata sig, address signer) external pure returns (bool) {
        return hash.recover(sig) == signer;
    }
}

//////////////////////////////////////////////////////
// 3) Address Library
//////////////////////////////////////////////////////
library InsecureAddress {
    function sendValue(address payable to, uint256 amount) internal {
        // uses transfer: may revert if gas cost changes
        to.transfer(amount);
    }
}

library SecureAddress {
    function sendValue(address payable to, uint256 amount) internal {
        // use call with stipend and check return
        (bool ok,) = to.call{ value: amount, gas: 2300 }("");
        require(ok, "Address: unable to send value");
    }
}

contract AddressUser is ReentrancyGuard {
    using InsecureAddress for address payable;
    using SecureAddress   for address payable;

    // fund contract
    receive() external payable {}

    // --- Attack: may revert on high-gas recipient
    function payInsecure(address payable to, uint256 amt) external {
        to.sendValue(amt);  // transfer under InsecureAddress
    }

    // --- Defense: safe call
    function paySecure(address payable to, uint256 amt) external nonReentrant {
        to.sendValue(amt);  // call under SecureAddress
    }
}
