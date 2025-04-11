// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FomoLottery {
    address public lastParticipant;
    uint256 public lastTime;
    uint256 public timer = 1 minutes;
    uint256 public pot;

    /// ✅ Declare before receive() and mark as public payable
    function enter() public payable {
        require(msg.value >= 0.01 ether, "Min 0.01 ETH");
        lastParticipant = msg.sender;
        lastTime = block.timestamp;
        pot += msg.value;
    }

    function claim() external {
        require(block.timestamp > lastTime + timer, "Too soon");
        require(msg.sender == lastParticipant, "Not last");

        uint256 amount = pot;
        pot = 0;

        payable(msg.sender).transfer(amount);
    }

    /// ✅ Now works because enter() is visible above
    receive() external payable {
        enter();
    }
}
