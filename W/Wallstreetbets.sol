// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title WSBMemePool - Community-powered long/short meme betting arena
contract WSBMemePool {
    enum Position { NONE, LONG, SHORT }

    struct Bet {
        uint256 amount;
        Position direction;
        uint256 round;
        bool claimed;
    }

    address public immutable token; // ERC20 used for staking
    uint256 public currentRound;
    uint256 public roundStart;
    uint256 public roundDuration = 1 hours;

    mapping(address => Bet) public userBets;
    mapping(uint256 => uint256) public totalLong;
    mapping(uint256 => uint256) public totalShort;

    event BetPlaced(address indexed user, Position dir, uint256 amt, uint256 round);
    event RoundResolved(uint256 round, Position result);
    event PayoutClaimed(address indexed user, uint256 amount);

    Position public roundResult;
    bool public roundResolved;

    constructor(address _token) {
        token = _token;
        roundStart = block.timestamp;
        currentRound = 1;
    }

    function betLong(uint256 amount) external {
        _placeBet(amount, Position.LONG);
    }

    function betShort(uint256 amount) external {
        _placeBet(amount, Position.SHORT);
    }

    function _placeBet(uint256 amount, Position dir) internal {
        require(block.timestamp < roundStart + roundDuration, "Betting closed");
        require(userBets[msg.sender].round != currentRound, "Already bet");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        userBets[msg.sender] = Bet({
            amount: amount,
            direction: dir,
            round: currentRound,
            claimed: false
        });

        if (dir == Position.LONG) totalLong[currentRound] += amount;
        else totalShort[currentRound] += amount;

        emit BetPlaced(msg.sender, dir, amount, currentRound);
    }

    function resolveRound(Position outcome) external {
        require(!roundResolved, "Already resolved");
        require(block.timestamp >= roundStart + roundDuration, "Round ongoing");

        roundResult = outcome;
        roundResolved = true;

        emit RoundResolved(currentRound, outcome);
    }

    function claim() external {
        Bet storage b = userBets[msg.sender];
        require(b.round == currentRound, "Not this round");
        require(!b.claimed, "Already claimed");
        require(roundResolved, "Round not resolved");

        if (b.direction != roundResult) {
            b.claimed = true; // no payout
            return;
        }

        uint256 rewardPool = roundResult == Position.LONG ? totalShort[currentRound] : totalLong[currentRound];
        uint256 winnerPool = roundResult == Position.LONG ? totalLong[currentRound] : totalShort[currentRound];
        uint256 payout = b.amount + (b.amount * rewardPool) / winnerPool;

        b.claimed = true;
        IERC20(token).transfer(msg.sender, payout);

        emit PayoutClaimed(msg.sender, payout);
    }

    function nextRound() external {
        require(roundResolved, "Previous round not resolved");
        currentRound++;
        roundStart = block.timestamp;
        roundResolved = false;
        roundResult = Position.NONE;
    }
}

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}
