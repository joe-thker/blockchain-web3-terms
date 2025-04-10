// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FlatcoinCPI is ERC20, Ownable {
    uint256 public baseCPI = 10000;     // base CPI (e.g., 100.00 x100)
    uint256 public currentCPI = 10000;
    uint256 public lastMint;

    address public oracle;

    modifier onlyOracle() {
        require(msg.sender == oracle, "Not oracle");
        _;
    }

    constructor() ERC20("FlatcoinCPI", "FLATCPI") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 ether);
        lastMint = block.timestamp;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }

    function updateCPI(uint256 newCPI) external onlyOracle {
        require(newCPI > 0, "Invalid CPI");
        currentCPI = newCPI;
    }

    function mintForInflation() external onlyOwner {
        require(block.timestamp >= lastMint + 30 days, "Wait a month");
        require(currentCPI > baseCPI, "No inflation");

        uint256 inflationRate = ((currentCPI - baseCPI) * 1e18) / baseCPI;
        uint256 mintAmount = (totalSupply() * inflationRate) / 1e18;

        _mint(owner(), mintAmount);
        baseCPI = currentCPI;
        lastMint = block.timestamp;
    }
}
