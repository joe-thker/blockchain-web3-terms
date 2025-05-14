// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenMinter is ERC20 {
    address public admin;

    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        admin = msg.sender;
        _mint(msg.sender, initialSupply * 1 ether);
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == admin, "Only admin can mint");
        _mint(to, amount);
    }
}
