// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NewbDividend
/// @notice ERC20 token that accrues dividends (interest) over time.
contract NewbDividend is ERC20, Ownable {
    uint256 public lastAccrual;
    // Interest rate per second, e.g. 1e14 represents ~0.0001% per second
    uint256 public interestRatePerSecond = 1e14;
    
    // Record initial principal at last accrual per user
    mapping(address => uint256) public lastPrincipal;
    // Record last accrual timestamp per user
    mapping(address => uint256) public lastAccrualTimestamp;

    constructor(address initialOwner) ERC20("Newb Dividend", "NEWB-D") Ownable(initialOwner) {
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
        lastAccrual = block.timestamp;
        lastPrincipal[initialOwner] = balanceOf(initialOwner);
        lastAccrualTimestamp[initialOwner] = block.timestamp;
    }
    
    /// @notice Internal function to accrue interest for a user.
    function _accrue(address account) internal {
        uint256 timeElapsed = block.timestamp - lastAccrualTimestamp[account];
        if (timeElapsed > 0 && balanceOf(account) > 0) {
            uint256 principal = lastPrincipal[account];
            uint256 interest = (principal * interestRatePerSecond * timeElapsed) / 1e18;
            if (interest > 0) {
                _mint(account, interest);
            }
            lastPrincipal[account] = balanceOf(account);
            lastAccrualTimestamp[account] = block.timestamp;
        }
    }
    
    /// @notice Override transfer to accrue interest before transfer.
    function transfer(address to, uint256 amount) public override returns (bool) {
        _accrue(msg.sender);
        _accrue(to);
        return super.transfer(to, amount);
    }
    
    /// @notice Override transferFrom to accrue interest before transfer.
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _accrue(from);
        _accrue(to);
        return super.transferFrom(from, to, amount);
    }
    
    /// @notice Owner can update the interest rate.
    function setInterestRate(uint256 newRate) external onlyOwner {
        interestRatePerSecond = newRate;
    }
}
