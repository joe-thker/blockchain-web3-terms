// CapitalGains.sol
pragma solidity ^0.8.20;

contract CapitalGains {
    mapping(address => uint256) public buyPrice;
    uint256 public currentPrice = 1e18;

    function buy() external {
        buyPrice[msg.sender] = currentPrice;
    }

    function sell() external view returns (int256 gain) {
        uint256 initial = buyPrice[msg.sender];
        gain = int256(currentPrice) - int256(initial);
    }

    function updatePrice(uint256 newPrice) external {
        currentPrice = newPrice;
    }
}
