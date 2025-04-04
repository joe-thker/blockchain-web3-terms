// AirdropGains.sol
pragma solidity ^0.8.20;

contract AirdropGains {
    mapping(address => bool) public claimed;

    function claimAirdrop() external {
        require(!claimed[msg.sender], "Already claimed");
        claimed[msg.sender] = true;
        payable(msg.sender).transfer(1 ether); // mock airdrop
    }

    receive() external payable {}
}
