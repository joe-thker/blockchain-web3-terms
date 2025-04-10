// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FlatcoinStaked
 * @dev A CPI-pegged flatcoin that gives inflation-based yield to stakers
 */
contract FlatcoinStaked is ERC20, Ownable {
    uint256 public yieldRate = 3; // 3% annual inflation yield
    mapping(address => uint256) public stakeBalances;
    mapping(address => uint256) public lastClaim;

    constructor() ERC20("FlatcoinStaked", "FLATS") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 ether); // Initial supply
    }

    /**
     * @notice Stake FLATS tokens to earn yield
     */
    function stake(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        claim(); // claim any pending yield

        _transfer(msg.sender, address(this), amount);
        stakeBalances[msg.sender] += amount;
        lastClaim[msg.sender] = block.timestamp;
    }

    /**
     * @notice Claim inflation-adjusted yield
     */
    function claim() public {
        uint256 staked = stakeBalances[msg.sender];
        if (staked == 0) return;

        uint256 timeElapsed = block.timestamp - lastClaim[msg.sender];
        uint256 reward = (staked * yieldRate * timeElapsed) / (365 days * 100);
        if (reward > 0) {
            _mint(msg.sender, reward);
        }

        lastClaim[msg.sender] = block.timestamp;
    }

    /**
     * @notice Unstake FLATS and stop earning yield
     */
    function unstake(uint256 amount) external {
        require(stakeBalances[msg.sender] >= amount, "Not enough staked");
        claim();
        stakeBalances[msg.sender] -= amount;
        _transfer(address(this), msg.sender, amount);
    }
}
