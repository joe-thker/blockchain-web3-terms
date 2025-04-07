// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MintAttackUpgradeable is ERC20 {
    address public owner;

    constructor() ERC20("ProxyToken", "PROXY") {
        owner = msg.sender;
    }

    // ✅ Appears safe...
    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "Only owner");
        _mint(to, amount);
    }

    // ❌ In upgradeable/proxy architecture, this function can be replaced
    // with one that removes the `require` or allows arbitrary minting
}
