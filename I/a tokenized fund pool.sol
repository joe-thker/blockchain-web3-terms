// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title TokenizedFundPool
/// @notice Tokenized on-chain investment fund that mints pool shares for USDC deposits.
contract TokenizedFundPool is ERC20Burnable, Ownable {
    IERC20 public immutable usdc;

    constructor(address _usdc) ERC20("Fund Pool Share", "FPS") Ownable(msg.sender) {
        usdc = IERC20(_usdc);
    }

    /// @notice Deposit USDC to receive Fund Pool Shares
    function deposit(uint256 amount) external {
        require(amount > 0, "Zero deposit");

        // Determine amount of FPS to mint
        uint256 totalUSDC = usdc.balanceOf(address(this));
        uint256 totalShares = totalSupply();

        uint256 shares;
        if (totalShares == 0 || totalUSDC == 0) {
            shares = amount; // 1:1 initial
        } else {
            shares = (amount * totalShares) / totalUSDC;
        }

        usdc.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, shares);
    }

    /// @notice Redeem fund shares for proportional USDC
    function withdraw(uint256 shareAmount) external {
        require(shareAmount > 0, "Zero amount");

        uint256 totalShares = totalSupply();
        uint256 totalUSDC = usdc.balanceOf(address(this));

        uint256 payout = (shareAmount * totalUSDC) / totalShares;
        _burn(msg.sender, shareAmount);
        usdc.transfer(msg.sender, payout);
    }

    /// @notice Admin-only: move USDC into a yield strategy
    function transferOut(address to, uint256 amount) external onlyOwner {
        usdc.transfer(to, amount);
    }

    /// @notice Admin-only: receive USDC from external yield strategy
    function receiveYield(uint256 amount) external onlyOwner {
        usdc.transferFrom(msg.sender, address(this), amount);
    }
}
