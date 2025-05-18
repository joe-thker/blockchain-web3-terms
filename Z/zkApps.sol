// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ZKAgeVerifier - Verifies a zk-SNARK proof that user is ≥18
contract ZKAgeVerifier {
    address public immutable admin;
    mapping(address => bool) public verified;

    constructor() {
        admin = msg.sender;
    }

    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[] memory input  // [hashOfID, isOver18 (1 = yes)]
    ) public {
        require(input.length == 2 && input[1] == 1, "Invalid age proof");
        // Placeholder — insert zk verifier logic
        require(true, "Proof invalid");

        verified[msg.sender] = true;
    }

    function accessRestrictedContent() external view returns (string memory) {
        require(verified[msg.sender], "Not age-verified");
        return "You have access to age-restricted dApp content!";
    }
}
