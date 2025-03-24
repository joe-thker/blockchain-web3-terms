// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DecentralizedCoinMixer
/// @notice A simplified simulation of a decentralized coin mixer using hash locks.
/// Users deposit Ether along with a hash lock. Later, by providing the preimage, they can withdraw their funds.
contract DecentralizedCoinMixer {
    uint256 public nextDepositId;

    struct Deposit {
        address depositor;
        uint256 amount;
        bytes32 hashLock; // Hash of the secret
        bool withdrawn;
    }

    mapping(uint256 => Deposit) public deposits;

    event DepositMade(uint256 indexed depositId, address indexed depositor, uint256 amount, bytes32 hashLock);
    event WithdrawalMade(uint256 indexed depositId, address indexed depositor, uint256 amount);

    /// @notice Users deposit Ether with a hash lock.
    /// @param hashLock The hash of the secret (preimage) for withdrawal.
    /// @return depositId The assigned deposit ID.
    function deposit(bytes32 hashLock) external payable returns (uint256 depositId) {
        require(msg.value > 0, "Deposit must be > 0");
        depositId = nextDepositId;
        deposits[depositId] = Deposit({
            depositor: msg.sender,
            amount: msg.value,
            hashLock: hashLock,
            withdrawn: false
        });
        nextDepositId++;
        emit DepositMade(depositId, msg.sender, msg.value, hashLock);
    }

    /// @notice Withdraws funds by providing the correct preimage (secret) that hashes to the stored hash lock.
    /// @param depositId The deposit ID.
    /// @param preimage The secret value whose hash must match the stored hashLock.
    function withdraw(uint256 depositId, string calldata preimage) external {
        Deposit storage dep = deposits[depositId];
        require(dep.amount > 0, "Invalid deposit");
        require(!dep.withdrawn, "Already withdrawn");
        require(keccak256(abi.encodePacked(preimage)) == dep.hashLock, "Invalid preimage");
        dep.withdrawn = true;
        (bool success, ) = dep.depositor.call{value: dep.amount}("");
        require(success, "Transfer failed");
        emit WithdrawalMade(depositId, dep.depositor, dep.amount);
    }
}
