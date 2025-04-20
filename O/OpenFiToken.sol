// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * OpenFiToken (OFT)
 * – Fixed supply: 1 000 000 OFT minted to treasury on deploy.
 */
contract OpenFiToken is ERC20, Ownable {
    uint256 public constant CAP = 1_000_000e18;

    constructor(address treasury)
        ERC20("Open Finance Token", "OFT")
        Ownable(msg.sender)
    {
        _mint(treasury, CAP);
    }
}
