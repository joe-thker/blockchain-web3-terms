// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SmartContractPatterns
/// @notice Illustrates insecure vs. secure patterns for Ownership, Fund Handling, and Upgradeable Proxy
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() {
        owner = msg.sender;
    }
}

/// Simple reentrancy guard
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
// 1) Ownership & Access Control
//////////////////////////////////////////////////////
contract AccessControlExample is Base {
    string public data;

    // --- Attack: no access control
    function setDataInsecure(string calldata x) external {
        data = x;
    }

    // --- Defense: onlyOwner
    function setDataSecure(string calldata x) external onlyOwner {
        data = x;
    }

    // --- Attack: no initializer => owner=0x0 on proxy
    function initializeInsecure(address newOwner) external {
        owner = newOwner;
    }

    // --- Defense: initialize once
    bool private _initialized;
    function initializeSecure(address newOwner) external {
        require(!_initialized, "Already initialized");
        owner = newOwner;
        _initialized = true;
    }
}

//////////////////////////////////////////////////////
// 2) Fund Reception & Withdrawal
//////////////////////////////////////////////////////
contract FundReceiverExample is Base, ReentrancyGuard {
    // --- Attack: no checks, no reentrancy guard
    function depositInsecure() external payable {
        // accept any ETH
    }

    function withdrawInsecure(uint256 amt) external {
        // no CEI, vulnerable to reentrancy
        payable(msg.sender).call{ value: amt }("");
    }

    // --- Defense: require minimum, CEI + nonReentrant
    function depositSecure() external payable {
        require(msg.value > 0.01 ether, "Min 0.01 ETH");
    }

    function withdrawSecure(uint256 amt) external nonReentrant {
        require(address(this).balance >= amt, "Insufficient");
        // Effects done by nonReentrant guard
        (bool ok, ) = payable(msg.sender).call{ value: amt, gas: 2300 }("");
        require(ok, "Transfer failed");
    }

    receive() external payable {}
}

//////////////////////////////////////////////////////
// 3) Upgradeable Proxy (UUPS-style)
//////////////////////////////////////////////////////
contract ProxyExample is Base {
    // EIP-1967 implementation slot
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    // --- Attack: anyone can upgrade
    function upgradeToInsecure(address impl) external {
        assembly { sstore(_IMPLEMENTATION_SLOT, impl) }
    }

    // --- Defense: onlyOwner + codehash check
    function upgradeToSecure(address impl, bytes32 expectedCodeHash) external onlyOwner {
        bytes32 codeHash;
        assembly { codeHash := extcodehash(impl) }
        require(codeHash == expectedCodeHash, "Bad implementation");
        assembly { sstore(_IMPLEMENTATION_SLOT, impl) }
    }

    // Fallback to delegate
    fallback() external payable {
        assembly {
            let impl := sload(_IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let ok := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch ok case 0 { revert(0, returndatasize()) } default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
