// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TradingTournamentModule - Trading Game with ROI + Volume Leaderboard + Defense

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

/// 📊 Tournament Vault
contract TournamentVault {
    mapping(address => uint256) public volumeScore;
    mapping(address => uint256) public roiScore;
    mapping(address => uint256) public deposits;
    mapping(address => bool) public entered;

    IERC20 public token;
    uint256 public startBlock;
    uint256 public endBlock;

    constructor(address _token, uint256 _duration) {
        token = IERC20(_token);
        startBlock = block.number;
        endBlock = block.number + _duration;
    }

    function enter(uint256 amount) external {
        require(!entered[msg.sender], "Already in");
        require(block.number < endBlock, "Too late");
        token.transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] = amount;
        entered[msg.sender] = true;
    }

    function logTrade(address user, uint256 volume, int256 roiDelta) external {
        require(entered[user], "Not in tournament");
        volumeScore[user] += volume;

        if (roiDelta > 0) {
            roiScore[user] += uint256(roiDelta);
        } else {
            roiScore[user] -= uint256(-roiDelta);
        }
    }

    function getVolumeScore(address user) external view returns (uint256) {
        return volumeScore[user];
    }

    function getROIScore(address user) external view returns (uint256) {
        return roiScore[user];
    }
}

/// 🔁 Tournament DEX
contract TournamentDEX {
    TournamentVault public vault;
    address public token;

    constructor(address _vault, address _token) {
        vault = TournamentVault(_vault);
        token = _token;
    }

    function swap(uint256 inAmt, bool profitable) external {
        IERC20(token).transferFrom(msg.sender, address(this), inAmt);
        uint256 outAmt = profitable ? inAmt * 105 / 100 : inAmt * 95 / 100;

        IERC20(token).transfer(msg.sender, outAmt);

        int256 roiDelta = int256(outAmt) - int256(inAmt);
        vault.logTrade(msg.sender, inAmt, roiDelta);
    }
}

/// 🎁 Reward Distributor
contract RewardDistributor {
    TournamentVault public vault;
    IERC20 public rewardToken;
    address public admin;

    constructor(address _vault, address _rewardToken) {
        vault = TournamentVault(_vault);
        rewardToken = IERC20(_rewardToken);
        admin = msg.sender;
    }

    function rewardTop(address[] calldata winners, uint256[] calldata amounts) external {
        require(msg.sender == admin, "Not admin");
        require(winners.length == amounts.length, "Mismatch");
        for (uint256 i = 0; i < winners.length; i++) {
            rewardToken.transfer(winners[i], amounts[i]);
        }
    }
}

/// 🔓 Tournament Attacker
interface ITournamentDEX {
    function swap(uint256, bool) external;
}

contract TournamentAttacker {
    function washTrade(ITournamentDEX dex, uint256 loops, uint256 amt) external {
        for (uint256 i = 0; i < loops; i++) {
            dex.swap(amt, true);
            dex.swap(amt, false);
        }
    }
}
