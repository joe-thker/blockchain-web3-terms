// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SimpleTumbler - Demonstrates basic ETH mixer via hash preimage withdrawal

contract SimpleTumbler {
    struct Deposit {
        uint256 amount;
        bool withdrawn;
    }

    mapping(bytes32 => Deposit) public deposits;

    event Deposited(bytes32 indexed commitment, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    /// @notice Deposit with commitment = hash(secret)
    function deposit(bytes32 commitment) external payable {
        require(deposits[commitment].amount == 0, "Already used");
        require(msg.value > 0, "Must deposit ETH");

        deposits[commitment] = Deposit(msg.value, false);
        emit Deposited(commitment, msg.value);
    }

    /// @notice Withdraw using secret preimage (e.g., secret phrase or number)
    function withdraw(bytes32 secret, address payable to) external {
        bytes32 commitment = keccak256(abi.encodePacked(secret));
        Deposit storage dep = deposits[commitment];

        require(dep.amount > 0, "Invalid secret");
        require(!dep.withdrawn, "Already withdrawn");

        dep.withdrawn = true;
        to.transfer(dep.amount);

        emit Withdrawn(to, dep.amount);
    }
}
