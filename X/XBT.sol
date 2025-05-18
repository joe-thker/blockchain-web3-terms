// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title XBTToken - ERC20 Token Representing Bitcoin in ISO Style
contract XBTToken is ERC20 {
    address public admin;

    constructor() ERC20("Synthetic Bitcoin", "XBT") {
        admin = msg.sender;
        _mint(msg.sender, 21_000_000 * 1e8); // 21M max supply, 8 decimals
    }

    function decimals() public pure override returns (uint8) {
        return 8; // Matches Bitcoin
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == admin, "Not authorized");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == admin, "Not authorized");
        _burn(from, amount);
    }
}
