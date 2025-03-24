// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title PaymentCoin
/// @notice A basic ERC20 coin that serves as a medium of exchange.
contract PaymentCoin is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("PaymentCoin", "PAY") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }
}
