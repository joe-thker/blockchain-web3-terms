// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract PutOption {
    address public buyer;
    IERC20 public token;
    uint256 public strikePrice; // in wei (ETH per token)
    uint256 public amount;
    uint256 public expiry;
    bool public exercised;

    constructor(address _buyer, address _token, uint256 _strikePrice, uint256 _amount, uint256 _duration) payable {
        require(msg.value == _strikePrice * _amount, "Incorrect hedge reserve");
        buyer = _buyer;
        token = IERC20(_token);
        strikePrice = _strikePrice;
        amount = _amount;
        expiry = block.timestamp + _duration;
    }

    function exercise() external {
        require(msg.sender == buyer, "Not buyer");
        require(!exercised, "Already exercised");
        require(block.timestamp <= expiry, "Expired");

        exercised = true;
        token.transferFrom(msg.sender, address(this), amount); // send tokens to contract
        payable(msg.sender).transfer(strikePrice * amount);    // send ETH to buyer
    }

    function refund() external {
        require(block.timestamp > expiry, "Not expired");
        require(!exercised, "Already exercised");
        payable(msg.sender).transfer(address(this).balance);
    }
}
