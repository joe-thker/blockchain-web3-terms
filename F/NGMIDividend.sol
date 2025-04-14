// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NGMIDividendToken
/// @notice ERC20 token called "NGMI Dividend" (symbol: NGMI-D) that accrues dividends over time.
contract NGMIDividendToken is ERC20, Ownable {
    uint256 public lastAccrual;
    // Interest rate per second, for example, 1e14 ≈ 0.000001 per second (approx. 8.64% per day if compounded continuously, adjust as needed)
    uint256 public interestRatePerSecond = 1e14;

    // For each user, we record their principal and the last time interest was accrued.
    mapping(address => uint256) public lastPrincipal;
    mapping(address => uint256) public lastAccrualTimestamp;

    constructor(address initialOwner)
        ERC20("NGMI Dividend", "NGMI-D")
        Ownable(initialOwner)
    {
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
        lastAccrual = block.timestamp;
        lastPrincipal[initialOwner] = balanceOf(initialOwner);
        lastAccrualTimestamp[initialOwner] = block.timestamp;
    }

    /// @notice Accrue interest for a given user.
    function _accrue(address account) internal {
        uint256 elapsed = block.timestamp - lastAccrualTimestamp[account];
        if (elapsed > 0 && balanceOf(account) > 0) {
            uint256 principal = lastPrincipal[account];
            uint256 interest = (principal * interestRatePerSecond * elapsed) / 1e18;
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

    /// @notice Mint new tokens (only owner).
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
