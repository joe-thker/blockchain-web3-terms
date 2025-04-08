// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract InterestVault {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public depositTimestamps;
    uint256 public interestRatePerSecond = 3171; // ~10% APR (in 1e18 units)

    function deposit() external payable {
        require(msg.value > 0, "No ETH");
        if (deposits[msg.sender] > 0) {
            _claimInterest();
        }
        deposits[msg.sender] += msg.value;
        depositTimestamps[msg.sender] = block.timestamp;
    }

    function withdraw(uint256 amount) external {
        require(deposits[msg.sender] >= amount, "Insufficient");
        _claimInterest();
        deposits[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function _claimInterest() internal {
        uint256 timeElapsed = block.timestamp - depositTimestamps[msg.sender];
        uint256 interest = (deposits[msg.sender] * interestRatePerSecond * timeElapsed) / 1e18;
        depositTimestamps[msg.sender] = block.timestamp;
        if (interest > 0) payable(msg.sender).transfer(interest);
    }
}
