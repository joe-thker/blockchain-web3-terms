// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FlatcoinRebase
 * @dev A rebasing flatcoin that adjusts balances over time to reflect CPI/inflation.
 */
contract FlatcoinRebase is ERC20Burnable, Ownable {
    uint256 public index = 1e18; // Scaling factor
    mapping(address => uint256) internal rawBalances;
    uint256 public totalRawSupply;

    constructor() ERC20("FlatcoinRebase", "FLATR") Ownable(msg.sender) {}

    function _scaled(uint256 raw) internal view returns (uint256) {
        return (raw * index) / 1e18;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _scaled(rawBalances[account]);
    }

    function totalSupply() public view override returns (uint256) {
        return _scaled(totalRawSupply);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 rawAmount = (amount * 1e18) / index;
        require(rawBalances[msg.sender] >= rawAmount, "Insufficient balance");
        rawBalances[msg.sender] -= rawAmount;
        rawBalances[to] += rawAmount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        uint256 raw = (amount * 1e18) / index;
        rawBalances[to] += raw;
        totalRawSupply += raw;
        emit Transfer(address(0), to, amount);
    }

    function rebase(uint256 newIndex) external onlyOwner {
        require(newIndex > 0, "Invalid index");
        index = newIndex;
    }
}
