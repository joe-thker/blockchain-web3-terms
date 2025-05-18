// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ProjectToken - Sample whitepaper-based tokenomics contract
contract ProjectToken {
    string public name = "Whitepaper Token";
    string public symbol = "WPT";
    uint8 public decimals = 18;
    uint256 public immutable totalSupply;

    address public immutable teamWallet;
    address public immutable communityWallet;
    uint256 public immutable launchTime;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address _team, address _community) {
        teamWallet = _team;
        communityWallet = _community;
        launchTime = block.timestamp;

        uint256 supply = 100_000_000 * 1e18;
        totalSupply = supply;

        // Distribute tokens
        balanceOf[_team] = (supply * 30) / 100;        // 30% team
        balanceOf[_community] = (supply * 70) / 100;   // 70% community

        emit Transfer(address(0), _team, balanceOf[_team]);
        emit Transfer(address(0), _community, balanceOf[_community]);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient");

        // Team vesting restriction: 1-year cliff
        if (msg.sender == teamWallet) {
            require(block.timestamp >= launchTime + 365 days, "Team tokens locked");
        }

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient");
        require(allowance[from][msg.sender] >= amount, "Not approved");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }
}
