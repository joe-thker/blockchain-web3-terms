// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AllDataValidations is Ownable, ReentrancyGuard {
    
    // Storage example for uniqueness validation
    mapping(string => bool) private uniqueStrings;
    
    // Events
    event RangeValidated(address indexed user, uint256 value);
    event FormatValidated(address indexed user, string email);
    event LengthValidated(address indexed user, string data);
    event PresenceValidated(address indexed user, string data);
    event TypeValidated(address indexed user, bytes data);
    event UniquenessValidated(address indexed user, string data);
    event CustomValidated(address indexed user, uint256 data);

    constructor() Ownable(msg.sender) {}

    // 1️⃣ Range Validation (Number between 1 and 100 inclusive)
    function validateRange(uint256 value) external nonReentrant {
        require(value >= 1 && value <= 100, "Value out of acceptable range (1-100)");
        emit RangeValidated(msg.sender, value);
    }

    // 2️⃣ Format Validation (Simple email-like validation)
    function validateFormat(string calldata email) external nonReentrant {
        bytes memory emailBytes = bytes(email);
        require(emailBytes.length > 5 && emailBytes.length < 64, "Invalid email length");

        bool hasAt;
        for (uint i = 0; i < emailBytes.length; i++) {
            if (emailBytes[i] == "@") {
                hasAt = true;
                break;
            }
        }
        require(hasAt, "Invalid email format");
        emit FormatValidated(msg.sender, email);
    }

    // 3️⃣ Length Validation (String length between 3 and 10 characters)
    function validateLength(string calldata data) external nonReentrant {
        bytes memory dataBytes = bytes(data);
        require(dataBytes.length >= 3 && dataBytes.length <= 10, "Data length out of bounds (3-10 chars)");
        emit LengthValidated(msg.sender, data);
    }

    // 4️⃣ Presence Validation (Non-empty string)
    function validatePresence(string calldata data) external nonReentrant {
        require(bytes(data).length > 0, "Data cannot be empty");
        emit PresenceValidated(msg.sender, data);
    }

    // 5️⃣ Type Validation (Ensuring input is exactly 32 bytes)
    function validateType(bytes calldata data) external nonReentrant {
        require(data.length == 32, "Data must be exactly 32 bytes");
        emit TypeValidated(msg.sender, data);
    }

    // 6️⃣ Uniqueness Validation (Ensuring the string hasn't been used before)
    function validateUniqueness(string calldata data) external nonReentrant {
        require(!uniqueStrings[data], "Data must be unique");
        uniqueStrings[data] = true;
        emit UniquenessValidated(msg.sender, data);
    }

    // 7️⃣ Custom Validation (Number must be even and divisible by 10)
    function validateCustom(uint256 data) external nonReentrant {
        require(data % 2 == 0 && data % 10 == 0, "Number must be even and divisible by 10");
        emit CustomValidated(msg.sender, data);
    }
}
