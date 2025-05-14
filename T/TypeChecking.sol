// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TypeCheckingExample - Demonstrates Solidity type checking features

interface IBadCall {
    function setValue(uint8 val) external;
}

contract TypeCheckingExample {
    uint256 public largeNumber;
    uint8 public smallNumber;
    address public savedAddress;

    struct Person {
        string name;
        uint256 age;
    }

    mapping(address => Person) public people;

    /// ✅ Safe assignment (uint8 to uint256)
    function setLarge(uint8 value) external {
        largeNumber = value; // Safe: upcasting
    }

    /// ⚠️ Unsafe assignment (uint256 to uint8)
    function setSmall(uint256 value) external {
        require(value <= type(uint8).max, "Overflow risk");
        smallNumber = uint8(value); // Manual check prevents truncation
    }

    /// 🧨 Type mismatch bug - ABI expects uint8, sends uint256
    function callBadInterface(address badTarget) external {
        IBadCall(badTarget).setValue(uint8(300)); // Must match declared type
    }

    /// ✅ Safe struct type checking
    function registerPerson(string calldata name, uint256 age) external {
        people[msg.sender] = Person(name, age);
    }

    /// 🧨 Dangerous cast (could lead to confusion)
    function storeAsAddress(uint256 input) external {
        savedAddress = address(uint160(input)); // Only safe if input is known to be an address
    }

    /// ✅ Strong typing with enums
    enum Status {Inactive, Active, Banned}
    Status public userStatus;

    function setStatus(uint8 index) external {
        require(index <= uint8(Status.Banned), "Invalid enum value");
        userStatus = Status(index); // Explicit enum cast
    }
}
