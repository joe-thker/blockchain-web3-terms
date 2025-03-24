// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title CentralizedCoinMixer
/// @notice A simplified simulation of a centralized coin mixer.
/// Users deposit Ether to receive a deposit ID. Later, the owner assigns a withdrawal address for each deposit.
/// The designated withdrawal address can then withdraw the funds.
contract CentralizedCoinMixer {
    address public owner;
    uint256 public nextDepositId;

    struct Deposit {
        address depositor;
        uint256 amount;
        bool withdrawn;
    }

    // Mapping of deposit ID to deposit details.
    mapping(uint256 => Deposit) public deposits;
    // Mapping of deposit ID to assigned withdrawal address.
    mapping(uint256 => address) public withdrawalAddresses;

    event DepositMade(uint256 indexed depositId, address indexed depositor, uint256 amount);
    event WithdrawalAddressSet(uint256 indexed depositId, address indexed withdrawalAddress);
    event WithdrawalMade(uint256 indexed depositId, address indexed withdrawalAddress, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    constructor() {
        owner = msg.sender;
        nextDepositId = 0;
    }

    /// @notice Users deposit Ether to participate in the mixer.
    /// @return depositId The assigned deposit ID.
    function deposit() external payable returns (uint256 depositId) {
        require(msg.value > 0, "Deposit must be > 0");
        depositId = nextDepositId;
        deposits[depositId] = Deposit({
            depositor: msg.sender,
            amount: msg.value,
            withdrawn: false
        });
        nextDepositId++;
        emit DepositMade(depositId, msg.sender, msg.value);
    }

    /// @notice The owner sets a withdrawal address for a specific deposit.
    /// @param depositId The deposit ID.
    /// @param withdrawalAddress The address that will be allowed to withdraw the funds.
    function setWithdrawalAddress(uint256 depositId, address withdrawalAddress) external onlyOwner {
        require(deposits[depositId].amount > 0, "Invalid deposit");
        withdrawalAddresses[depositId] = withdrawalAddress;
        emit WithdrawalAddressSet(depositId, withdrawalAddress);
    }

    /// @notice Withdraws the funds for a deposit using the assigned withdrawal address.
    /// @param depositId The deposit ID to withdraw.
    function withdraw(uint256 depositId) external {
        Deposit storage dep = deposits[depositId];
        require(dep.amount > 0, "Invalid deposit");
        require(!dep.withdrawn, "Already withdrawn");
        require(withdrawalAddresses[depositId] == msg.sender, "Not authorized to withdraw");
        dep.withdrawn = true;
        (bool success, ) = msg.sender.call{value: dep.amount}("");
        require(success, "Transfer failed");
        emit WithdrawalMade(depositId, msg.sender, dep.amount);
    }
}
