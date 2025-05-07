// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SolidityGotchasSuite
/// @notice Demonstrates tx.origin auth, unsafe delegatecall, and uninitialized storage pitfalls

/// ------------------------------------------------------------------------
/// 1) tx.origin Authorization
/// ------------------------------------------------------------------------
contract OriginAuth {
    address public owner;
    constructor() { owner = msg.sender; }

    // --- Attack: phishing via tx.origin
    function withdrawInsecure(uint256 amount) external {
        require(tx.origin == owner, "Not owner");
        payable(owner).transfer(amount);
    }

    // --- Defense: use msg.sender for direct caller check
    function withdrawSecure(uint256 amount) external {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(amount);
    }

    receive() external payable {}
}

/// ------------------------------------------------------------------------
/// 2) Proxy with delegatecall
/// ------------------------------------------------------------------------
contract DelegateProxy {
    address public implementation;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address impl) {
        implementation = impl;
        owner = msg.sender;
    }

    // --- Attack: no checks on implementation
    function upgradeInsecure(address newImpl) external onlyOwner {
        implementation = newImpl;
    }
    fallback() external payable {
        // blindly delegate to implementation
        (bool ok, ) = implementation.delegatecall(msg.data);
        require(ok, "delegatecall failed");
    }

    // --- Defense: check extcodesize and whitelist
    mapping(address => bool) public allowedImpl;
    function whitelistImpl(address impl, bool ok) external onlyOwner {
        allowedImpl[impl] = ok;
    }
    function upgradeSecure(address newImpl) external onlyOwner {
        require(allowedImpl[newImpl], "Impl not whitelisted");
        uint256 size;
        // ensure contract at newImpl
        assembly { size := extcodesize(newImpl) }
        require(size > 0, "No code at impl");
        implementation = newImpl;
    }
    fallback(bytes calldata) external payable {
        (bool ok, ) = implementation.delegatecall(msg.data);
        require(ok, "delegatecall failed");
    }
}

/// ------------------------------------------------------------------------
/// 3) Uninitialized Storage Pointer
/// ------------------------------------------------------------------------
contract StoragePointer {
    struct Data { uint256 x; uint256 y; }
    Data public d;       // stored at slot 0 & 1
    Data[] public arr;   // dynamic array at slot 2

    // --- Attack: uninitialized 's' points to slot 0
    function writeInsecure(uint256 a, uint256 b) external {
        Data storage s;    // s.slot == 0 by default
        s.x = a;           // overwrites d.x
        s.y = b;           // overwrites d.y
    }

    // --- Defense: allocate properly or use memory
    function writeSecure(uint256 a, uint256 b) external {
        // option A: use memory for temporary
        Data memory tmp = Data(a, b);
        arr.push(tmp);
    }

    // helpers to inspect
    function getD() external view returns (uint256, uint256) {
        return (d.x, d.y);
    }
    function getArr(uint256 i) external view returns (uint256, uint256) {
        Data storage s = arr[i];
        return (s.x, s.y);
    }
}
