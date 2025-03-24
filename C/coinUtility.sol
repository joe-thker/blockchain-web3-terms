// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title UtilityCoin
/// @notice An ERC20 token representing a utility coin for platform services.
contract UtilityCoin is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("UtilityCoin", "UTIL") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }
}
