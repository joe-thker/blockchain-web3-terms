// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TrojanModule - Simulates Trojanized Contracts and Mitigations

interface IERC20 {
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

/// 🧨 Trojan Contract (Appears Safe)
contract TrojanContract {
    address public owner;
    IERC20 public token;

    constructor(address _token) {
        owner = msg.sender;
        token = IERC20(_token);
    }

    function fakeDeposit(uint256 amount) external {
        // Looks safe: takes tokens from user
        token.transferFrom(msg.sender, address(this), amount);
    }

    function approveBackdoor(address victim) external {
        require(msg.sender == owner, "Not owner");
        // Dangerous: silently approve attacker to spend victim’s tokens
        token.approve(owner, type(uint256).max);
    }

    function sweep(address to) external {
        require(msg.sender == owner, "Only owner");
        token.transferFrom(address(this), to, tokenBalance());
    }

    function tokenBalance() public view returns (uint256) {
        return tokenBalance();
    }
}

/// 🧑 Innocent User (Interacts with Trojan)
contract InnocentUser {
    function useFakeVault(address vault, uint256 amt, address token) external {
        IERC20(token).approve(vault, amt);
        TrojanContract(vault).fakeDeposit(amt);
    }
}

/// 🛡️ Trojan Detector (Permission Scanner)
contract TrojanDetector {
    function hasBackdoor(bytes memory bytecode) public pure returns (bool) {
        return keccak256(bytecode) == keccak256(type(TrojanContract).creationCode);
    }

    function hasSelfDestruct(bytes memory bytecode) public pure returns (bool found) {
        assembly {
            let len := mload(bytecode)
            let data := add(bytecode, 0x20)
            for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                if eq(byte(0, mload(add(data, i))), 0xff) { found := true }
            }
        }
    }
}
