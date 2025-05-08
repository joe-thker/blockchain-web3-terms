// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//////////////////////////////////////////
// 1) Uninitialized Storage Pointer
//////////////////////////////////////////
contract StoragePointer {
    struct Data { uint256 x; uint256 y; }
    Data public d;       // occupies slots 0 & 1
    Data[] public arr;   // slot 2

    // --- Attack: s defaults to slot 0, overwrites d
    function writeInsecure(uint256 a, uint256 b) external {
        Data storage s;    // uninitialized ⇒ s.slot == 0
        s.x = a;           // corrupts d.x
        s.y = b;           // corrupts d.y
    }

    // --- Defense: use memory/new
    function writeSecure(uint256 a, uint256 b) external {
        Data memory tmp = Data(a, b);
        arr.push(tmp);     // safe: writes only to arr
    }

    function getD() external view returns (uint256, uint256) {
        return (d.x, d.y);
    }
    function getArr(uint256 i) external view returns (uint256, uint256) {
        return (arr[i].x, arr[i].y);
    }
}

//////////////////////////////////////////
// 2) Proxy Storage Collision
//////////////////////////////////////////
// --- Insecure: naïve implementation contract
contract ProxyCollisionInsecure {
    address public implementation;  // slot 0
    address public owner;           // slot 1 (added later!)
    // ...
}

// --- Secure: unstructured storage per EIP-1967
contract ProxyCollisionSecure {
    // proxy uses these fixed slots
    bytes32 internal constant _IMPLEMENTATION_SLOT = 
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant _ADMIN_SLOT = 
        0xb53127684a568b3173ae13b9f8a6016e019b0e70a5f4cf0fa9ebf6fcc3c348c8;

    function _setImplementation(address impl) internal {
        assembly { sstore(_IMPLEMENTATION_SLOT, impl) }
    }
    function _getImplementation() internal view returns (address impl) {
        assembly { impl := sload(_IMPLEMENTATION_SLOT) }
    }
    function _setAdmin(address adm) internal {
        assembly { sstore(_ADMIN_SLOT, adm) }
    }
    function _getAdmin() internal view returns (address adm) {
        assembly { adm := sload(_ADMIN_SLOT) }
    }
    // rest of proxy logic...
}

//////////////////////////////////////////
// 3) Unbounded Storage Iteration
//////////////////////////////////////////
contract StorageLoop is ReentrancyGuard {
    uint256[] public items;

    // --- Attack: unbounded loop drains gas when `items` is large
    function processAllInsecure() external {
        for (uint i = 0; i < items.length; i++) {
            _doWork(items[i]);
        }
    }

    // --- Defense: process in pages with cursor
    uint256 public cursor;
    uint256 public pageSize = 50;

    function processBatchSecure() external nonReentrant {
        uint256 len = items.length;
        uint256 end = cursor + pageSize;
        if (end > len) end = len;
        for (uint i = cursor; i < end; i++) {
            _doWork(items[i]);
        }
        cursor = end;
        // optionally reset when done
        if (cursor >= len) {
            cursor = 0;
        }
    }

    function _doWork(uint256 x) internal {
        // placeholder for real logic
    }

    function addItem(uint256 x) external {
        items.push(x);
    }
}
