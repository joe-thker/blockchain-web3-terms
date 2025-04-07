// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title 1. Fixed-Price IDO
contract FixedPriceIDO is Ownable {
    IERC20 public token;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public rate; // tokens per ETH
    uint256 public totalRaised;
    mapping(address => uint256) public contributions;

    constructor(IERC20 _token, uint256 _start, uint256 _end, uint256 _rate) Ownable(msg.sender) {
        require(_start < _end, "Invalid time");
        token = _token;
        startTime = _start;
        endTime = _end;
        rate = _rate;
    }

    function deposit() external payable {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Not sale time");
        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
    }

    function claim() external {
        require(block.timestamp > endTime, "Sale not ended");
        uint256 amount = contributions[msg.sender];
        require(amount > 0, "No contribution");
        contributions[msg.sender] = 0;
        token.transfer(msg.sender, amount * rate);
    }

    function withdrawETH(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }
}

/// @title 2. Whitelisted IDO
contract WhitelistIDO is Ownable {
    IERC20 public token;
    uint256 public rate;
    uint256 public startTime;
    uint256 public endTime;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public contributed;

    constructor(IERC20 _token, uint256 _rate, uint256 _start, uint256 _end) Ownable(msg.sender) {
        token = _token;
        rate = _rate;
        startTime = _start;
        endTime = _end;
    }

    function addToWhitelist(address user) external onlyOwner {
        whitelisted[user] = true;
    }

    function contribute() external payable {
        require(whitelisted[msg.sender], "Not whitelisted");
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Out of sale period");
        contributed[msg.sender] += msg.value;
    }

    function claim() external {
        require(block.timestamp > endTime, "Too early");
        uint256 amount = contributed[msg.sender];
        require(amount > 0, "Nothing to claim");
        contributed[msg.sender] = 0;
        token.transfer(msg.sender, amount * rate);
    }
}

/// @title 3. Overflow IDO (Fair Launch)
contract OverflowIDO is Ownable {
    IERC20 public token;
    uint256 public tokenAmount;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalETH;
    mapping(address => uint256) public userETH;
    bool public claimed;

    constructor(IERC20 _token, uint256 _amount, uint256 _start, uint256 _end) Ownable(msg.sender) {
        token = _token;
        tokenAmount = _amount;
        startTime = _start;
        endTime = _end;
    }

    function deposit() external payable {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Not active");
        userETH[msg.sender] += msg.value;
        totalETH += msg.value;
    }

    function claim() external {
        require(block.timestamp > endTime, "Too early");
        require(userETH[msg.sender] > 0, "No deposit");
        uint256 share = (userETH[msg.sender] * tokenAmount) / totalETH;
        userETH[msg.sender] = 0;
        token.transfer(msg.sender, share);
    }

    function withdrawETH(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }
}

/// @title 4. Dutch Auction IDO
contract DutchAuctionIDO is Ownable {
    IERC20 public token;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public startPrice;
    uint256 public floorPrice;
    uint256 public tokenSupply;
    uint256 public totalETH;
    mapping(address => uint256) public userETH;

    constructor(IERC20 _token, uint256 _supply, uint256 _start, uint256 _end, uint256 _startPrice, uint256 _floorPrice) Ownable(msg.sender) {
        token = _token;
        tokenSupply = _supply;
        startTime = _start;
        endTime = _end;
        startPrice = _startPrice;
        floorPrice = _floorPrice;
    }

    function getCurrentPrice() public view returns (uint256) {
        if (block.timestamp <= startTime) return startPrice;
        if (block.timestamp >= endTime) return floorPrice;
        uint256 duration = endTime - startTime;
        uint256 elapsed = block.timestamp - startTime;
        uint256 priceDiff = startPrice - floorPrice;
        return startPrice - (priceDiff * elapsed) / duration;
    }

    function buyTokens() external payable {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Not active");
        uint256 price = getCurrentPrice();
        uint256 tokens = (msg.value * 1e18) / price;
        require(tokens <= tokenSupply, "Exceeds supply");
        tokenSupply -= tokens;
        userETH[msg.sender] += msg.value;
        token.transfer(msg.sender, tokens);
    }

    function withdrawETH(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }
}
