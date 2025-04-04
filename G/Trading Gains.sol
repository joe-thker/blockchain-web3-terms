// TradingGains.sol
pragma solidity ^0.8.20;

contract TradingGains {
    struct Trade {
        uint256 entry;
        uint256 exit;
    }

    mapping(address => Trade[]) public trades;

    function recordTrade(uint256 entry, uint256 exit) external {
        trades[msg.sender].push(Trade(entry, exit));
    }

    function totalGains(address user) external view returns (int256 total) {
        Trade[] memory t = trades[user];
        for (uint i = 0; i < t.length; i++) {
            total += int256(t[i].exit) - int256(t[i].entry);
        }
    }
}
