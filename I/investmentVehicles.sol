// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title TokenizedFundVehicle
/// @notice Users deposit an ERC20 asset and receive share tokens
contract TokenizedFundVehicle is ERC20, Ownable {
    IERC20 public assetToken;
    uint256 public totalDeposited;

    constructor(address _asset) ERC20("Fund Shares", "FSH") Ownable(msg.sender) {
        assetToken = IERC20(_asset);
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        uint256 shares = totalSupply() == 0
            ? amount
            : (amount * totalSupply()) / getFundValue();

        assetToken.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, shares);
        totalDeposited += amount;
    }

    function withdraw(uint256 shares) external {
        require(balanceOf(msg.sender) >= shares, "Not enough shares");
        uint256 amount = (shares * getFundValue()) / totalSupply();
        _burn(msg.sender, shares);
        assetToken.transfer(msg.sender, amount);
        totalDeposited -= amount;
    }

    function getFundValue() public view returns (uint256) {
        return assetToken.balanceOf(address(this));
    }

    function simulateEarnings(uint256 profit) external onlyOwner {
        // Simulate strategy yield: owner sends profit to contract
        assetToken.transferFrom(msg.sender, address(this), profit);
    }
}
