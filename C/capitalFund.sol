// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CapitalFunds
/// @notice A simple contract to manage capital funds in a decentralized project.
///         Contributors can deposit funds to support a project, and the owner can withdraw funds.
contract CapitalFunds {
    address public owner;
    uint256 public totalCapital;
    mapping(address => uint256) public contributions;

    event ContributionReceived(address indexed contributor, uint256 amount);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the deployer as the contract owner.
    constructor() {
        owner = msg.sender;
    }

    /// @notice Allows anyone to contribute Ether to the capital funds.
    function contribute() public payable {
        require(msg.value > 0, "Contribution must be > 0");
        contributions[msg.sender] += msg.value;
        totalCapital += msg.value;
        emit ContributionReceived(msg.sender, msg.value);
    }

    /// @notice Returns the total capital funds available.
    /// @return The total amount of Ether contributed.
    function getTotalCapital() public view returns (uint256) {
        return totalCapital;
    }

    /// @notice Allows the owner to withdraw a specified amount of funds.
    /// @param amount The amount of Ether to withdraw.
    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient funds");
        totalCapital -= amount;
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "Withdrawal failed");
        emit FundsWithdrawn(owner, amount);
    }

    /// @notice Fallback function to receive Ether contributions.
    receive() external payable {
        contribute();
    }
}
