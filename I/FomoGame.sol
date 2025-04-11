// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FomoGame {
    address public lastDepositor;
    uint256 public lastDepositTime;
    uint256 public roundDuration = 5 minutes;
    uint256 public totalPot;
    bool public gameEnded;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    event Deposited(address indexed player, uint256 amount, uint256 newEndTime);
    event WinningsClaimed(address indexed winner, uint256 amount);
    event GameReset();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier gameActive() {
        require(!gameEnded, "Game has ended");
        _;
    }

    /// ✅ Visibility fix: Made public
    function deposit() public payable gameActive {
        require(msg.value > 0, "No ETH sent");

        lastDepositor = msg.sender;
        lastDepositTime = block.timestamp;
        totalPot += msg.value;

        emit Deposited(msg.sender, msg.value, block.timestamp + roundDuration);
    }

    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= lastDepositTime + roundDuration) {
            return 0;
        }
        return (lastDepositTime + roundDuration) - block.timestamp;
    }

    function claimWinnings() external {
        require(block.timestamp >= lastDepositTime + roundDuration, "Round not over");
        require(msg.sender == lastDepositor, "Not last depositor");
        require(!gameEnded, "Already claimed");

        gameEnded = true;
        uint256 reward = totalPot;
        totalPot = 0;

        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "Transfer failed");

        emit WinningsClaimed(msg.sender, reward);
    }

    function resetGame() external onlyOwner {
        require(gameEnded, "Game still active");

        lastDepositor = address(0);
        lastDepositTime = 0;
        totalPot = 0;
        gameEnded = false;

        emit GameReset();
    }

    /// ✅ Now safely calls deposit()
    receive() external payable {
        deposit();
    }
}
