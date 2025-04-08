// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title InvestmentVault
/// @notice Simple ETH investment vault with proportional shares
contract InvestmentVault {
    address public owner;
    uint256 public totalShares;
    uint256 public totalDeposits;

    mapping(address => uint256) public shares;

    constructor() {
        owner = msg.sender;
    }

    /// @notice Invest ETH into the vault
    function invest() external payable {
        require(msg.value > 0, "No ETH sent");

        uint256 newShares = totalShares == 0
            ? msg.value
            : (msg.value * totalShares) / address(this).balance;

        shares[msg.sender] += newShares;
        totalShares += newShares;
        totalDeposits += msg.value;
    }

    /// @notice View current share value in wei
    function shareValue() public view returns (uint256) {
        if (totalShares == 0) return 0;
        return address(this).balance / totalShares;
    }

    /// @notice Withdraw full investment share
    function withdraw() external {
        uint256 userShares = shares[msg.sender];
        require(userShares > 0, "No shares");

        uint256 amount = (address(this).balance * userShares) / totalShares;
        totalShares -= userShares;
        shares[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }

    /// @notice Receive ETH (e.g., yield from DeFi protocol)
    receive() external payable {}
}
