// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title FomoTokenSale
 * @dev Token price increases the longer the buyer waits (FOMO mechanism)
 */
contract FomoTokenSale is ERC20 {
    uint256 public start;
    uint256 public basePrice = 0.001 ether;

    constructor() ERC20("FomoToken", "FOMO") {
        start = block.timestamp;
        _mint(address(this), 1_000_000 * 10**18);
    }

    /// ✅ Returns current price based on elapsed time
    function currentPrice() public view returns (uint256) {
        uint256 minutesElapsed = (block.timestamp - start) / 60;
        return basePrice + (minutesElapsed * 0.0001 ether);
    }

    /// ✅ Moved above receive(), marked as public & payable
    function buy() public payable {
        uint256 price = currentPrice();
        require(price > 0, "Invalid price");
        uint256 tokens = (msg.value * 10**18) / price;
        require(balanceOf(address(this)) >= tokens, "Not enough tokens");
        _transfer(address(this), msg.sender, tokens);
    }

    /// ✅ Fallback function calls buy()
    receive() external payable {
        buy();
    }
}
