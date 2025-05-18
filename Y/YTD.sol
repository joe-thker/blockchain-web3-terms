// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

contract YTDTracker {
    IERC20 public immutable token;
    address public immutable vault;

    uint256 public ytdStartTimestamp;
    uint256 public ytdStartTVL;

    mapping(address => uint256) public ytdStartBalance;

    constructor(address _token, address _vault) {
        token = IERC20(_token);
        vault = _vault;
        ytdStartTimestamp = getJan1Timestamp();
        ytdStartTVL = token.balanceOf(vault);
    }

    /// @notice Store user's balance snapshot on Jan 1 (optional automation)
    function snapshotUser(address user) external {
        require(ytdStartBalance[user] == 0, "Already snapshotted");
        ytdStartBalance[user] = token.balanceOf(user);
    }

    /// @notice Get % change in user token balance since Jan 1
    function getUserYTDChange(address user) external view returns (int256) {
        uint256 nowBalance = token.balanceOf(user);
        uint256 startBalance = ytdStartBalance[user];
        if (startBalance == 0) return 0;

        return int256((nowBalance * 100) / startBalance) - 100;
    }

    /// @notice Get % TVL change from Jan 1
    function getTVLYTDChange() external view returns (int256) {
        uint256 nowTVL = token.balanceOf(vault);
        return int256((nowTVL * 100) / ytdStartTVL) - 100;
    }

    function getJan1Timestamp() internal view returns (uint256) {
        // Static for demo purposes: Jan 1, 2025 @ 00:00 UTC
        return 1735689600;
    }
}
