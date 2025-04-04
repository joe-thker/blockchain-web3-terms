// ImpermanentGains.sol
pragma solidity ^0.8.20;

contract ImpermanentGains {
    mapping(address => uint256) public liquidity;
    mapping(address => int256) public netGain;

    function provideLiquidity(uint256 amount) external {
        liquidity[msg.sender] += amount;
    }

    function simulateGain(int256 gain) external {
        netGain[msg.sender] = gain;
    }

    function withdraw() external view returns (int256 gainOrLoss) {
        gainOrLoss = netGain[msg.sender];
    }
}
