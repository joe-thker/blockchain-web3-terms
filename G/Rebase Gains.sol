// RebaseGains.sol
pragma solidity ^0.8.20;

contract RebaseToken {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function rebase(uint256 percent) external {
        for (uint256 i = 0; i < 10; i++) { // simulate small test
            balanceOf[msg.sender] += (balanceOf[msg.sender] * percent) / 100;
            totalSupply += (balanceOf[msg.sender] * percent) / 100;
        }
    }
}
