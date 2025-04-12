// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FUDster is ERC20, Ownable {
    struct Fudder {
        uint256 reputation;
        uint256 accusations;
        bool flagged;
    }

    mapping(address => Fudder) public fuddies;

    uint256 public constant FUD_REWARD = 10 * 1e18;
    uint256 public constant REPORT_REWARD = 5 * 1e18;
    uint256 public constant REPUTATION_PENALTY = 3;
    uint256 public constant FLAG_THRESHOLD = 5;

    event FUDSpread(address indexed fudder, string message);
    event FUDReported(address indexed target, address reporter);

    constructor(address initialOwner) ERC20("FUDster", "FUDS") Ownable(initialOwner) {
        _mint(initialOwner, 100_000 * 1e18);
    }

    /// 👻 Spread FUD to gain tokens, reputation goes down
    function spreadFUD(string calldata message) external {
        require(bytes(message).length > 5, "Too short");

        fuddies[msg.sender].reputation = fuddies[msg.sender].reputation > REPUTATION_PENALTY
            ? fuddies[msg.sender].reputation - REPUTATION_PENALTY
            : 0;

        if (fuddies[msg.sender].accusations >= FLAG_THRESHOLD) {
            fuddies[msg.sender].flagged = true;
        }

        _mint(msg.sender, FUD_REWARD);
        emit FUDSpread(msg.sender, message);
    }

    /// 👁 Anyone can report others for FUD (fake or real), and earn tokens
    function reportFudder(address target) external {
        require(target != msg.sender, "Can't report yourself");
        require(balanceOf(target) > 0, "Target inactive");

        fuddies[target].accusations += 1;
        if (fuddies[target].accusations >= FLAG_THRESHOLD) {
            fuddies[target].flagged = true;
        }

        _mint(msg.sender, REPORT_REWARD);
        emit FUDReported(target, msg.sender);
    }

    /// 👑 Admin can reset a user’s status
    function forgive(address fudder) external onlyOwner {
        fuddies[fudder].accusations = 0;
        fuddies[fudder].flagged = false;
    }

    function getFudderStatus(address user) external view returns (
        uint256 rep,
        uint256 accusations,
        bool flagged
    ) {
        Fudder memory f = fuddies[user];
        return (f.reputation, f.accusations, f.flagged);
    }
}
