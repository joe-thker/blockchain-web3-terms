// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BurnToMintToken is ERC20, Ownable {
    constructor() ERC20("BurnMint", "BMT") Ownable(msg.sender) {
        _mint(msg.sender, 100_000 * 1e18);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= 1_000_000 * 1e18, "Cap exceeded");
        _mint(to, amount);
    }
}
