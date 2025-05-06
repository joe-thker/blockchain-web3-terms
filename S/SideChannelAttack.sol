// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SideChannelSuite
/// @notice Demonstrates insecure vs. secure patterns for gas, timestamp, and revert‐reason side channels
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Simple reentrancy guard for safety
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// 1) Gas‐Usage Leak Module
contract GasLeak is Base {
    uint256 private secret;  // [0,3]

    constructor(uint256 _secret) {
        secret = _secret;
    }

    // --- Attack: branch on secret, leak via gasleft()
    function computeInsecure() external view returns (uint256 gasUsed) {
        uint256 before = gasleft();
        if (secret == 0) {
            // cheap path
            for (uint i = 0; i < 1; i++) { }
        } else if (secret == 1) {
            // medium path
            for (uint i = 0; i < 10; i++) { }
        } else if (secret == 2) {
            // heavier path
            for (uint i = 0; i < 100; i++) { }
        } else {
            // heaviest
            for (uint i = 0; i < 1000; i++) { }
        }
        uint256 after = gasleft();
        return before - after;
    }

    // --- Defense: constant‐gas loop padding to hide secret
    function computeSecure() external view returns (uint256) {
        // always consume same gas regardless of secret
        for (uint i = 0; i < 1000; i++) { /* dummy */ }
        // actual logic in constant branch
        // can't infer secret from gas
        return 0;
    }
}

/// 2) Timestamp Oracle Leak Module
contract TimestampLeak is Base {
    uint256 private secret;  // [0, 86400)

    constructor(uint256 _secret) {
        secret = _secret;
    }

    // --- Attack: branch on timestamp mod secret, exposes timing correlation
    function checkInsecure() external view returns (bool) {
        if (block.timestamp % secret == 0) {
            return true;
        }
        return false;
    }

    // --- Defense: avoid secret‐dependent timestamp checks
    function checkSecure() external view returns (bool) {
        // use blockhash instead (unpredictable in-contract)
        bytes32 h = blockhash(block.number - 1);
        // map h to 0–(secret-1) off‐chain; no on‐chain branching on secret
        return uint256(h) % 2 == 0;  
    }
}

/// 3) Revert‐Reason Disclosure Module
contract RevertLeak is Base {
    uint256 private secret;  // e.g. pin code

    constructor(uint256 _secret) {
        secret = _secret;
    }

    // --- Attack: detailed revert reveals secret on failure
    function unlockInsecure(uint256 guess) external pure {
        require(guess == guess, "placeholder"); // dummy
    }
    function guessSecretInsecure(uint256 guess) external view {
        require(guess == secret, string(abi.encodePacked("Secret is: ", _uint2str(secret))));
    }

    // --- Defense: custom errors without leaking secrets
    error IncorrectGuess();

    function guessSecretSecure(uint256 guess) external view {
        if (guess != secret) {
            revert IncorrectGuess();
        }
        // proceed on correct guess
    }

    // helper for insecure only
    function _uint2str(uint256 v) internal pure returns (string memory) {
        if (v == 0) return "0";
        uint256 w = v;
        uint256 digits;
        while (w != 0) {
            digits++;
            w /= 10;
        }
        bytes memory buf = new bytes(digits);
        while (v != 0) {
            digits -= 1;
            buf[digits] = bytes1(uint8(48 + uint256(v % 10)));
            v /= 10;
        }
        return string(buf);
    }
}
