// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiSigEscrow {
    address public depositor;
    address public beneficiary;
    address[3] public signers;
    mapping(address => bool) public approved;
    uint8 public approvals;

    event Approved(address signer);
    event Released(address to);

    constructor(address _beneficiary, address[3] memory _signers) payable {
        require(msg.value > 0, "Send ETH");
        depositor = msg.sender;
        beneficiary = _beneficiary;
        signers = _signers;
    }

    modifier onlySigner() {
        bool valid = false;
        for (uint8 i = 0; i < 3; i++) {
            if (msg.sender == signers[i]) {
                valid = true;
                break;
            }
        }
        require(valid, "Not a signer");
        _;
    }

    function approveRelease() external onlySigner {
        require(!approved[msg.sender], "Already approved");
        approved[msg.sender] = true;
        approvals++;
        emit Approved(msg.sender);

        if (approvals >= 2) {
            (bool sent, ) = beneficiary.call{value: address(this).balance}("");
            require(sent, "Release failed");
            emit Released(beneficiary);
        }
    }
}
