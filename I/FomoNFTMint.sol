// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FomoNFTMint {
    uint256 public mintStart = block.timestamp;
    uint256 public maxDiscount = 0.005 ether;
    uint256 public basePrice = 0.02 ether;

    event Minted(address indexed minter, uint256 paid);

    function getPrice() public view returns (uint256) {
        uint256 elapsed = block.timestamp - mintStart;
        uint256 decay = elapsed / 60; // every minute discount drops
        uint256 discount = decay > 50 ? 0 : maxDiscount - (decay * 0.0001 ether);
        return basePrice - discount;
    }

    function mint() external payable {
        uint256 price = getPrice();
        require(msg.value >= price, "Underpaid");
        emit Minted(msg.sender, msg.value);
    }
}
