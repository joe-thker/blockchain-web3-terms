// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LoopInstamine is ERC20, Ownable {
    bool public mined;

    constructor() ERC20("LoopInstamine", "LIM") Ownable(msg.sender) {}

    function instamine(address to) external onlyOwner {
        require(!mined, "Already mined");
        for (uint256 i = 0; i < 100; i++) {
            _mint(to, 10_000 * 1e18);
        }
        mined = true;
    }
}
