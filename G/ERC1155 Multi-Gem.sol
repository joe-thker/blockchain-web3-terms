// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MultiGem is ERC1155 {
    uint256 public constant RUBY = 1;
    uint256 public constant SAPPHIRE = 2;
    uint256 public constant EMERALD = 3;

    constructor() ERC1155("https://game.example/api/gem/{id}.json") {
        _mint(msg.sender, RUBY, 100, "");
        _mint(msg.sender, SAPPHIRE, 50, "");
        _mint(msg.sender, EMERALD, 25, "");
    }

    function mint(uint256 id, uint256 amount) external {
        _mint(msg.sender, id, amount, "");
    }
}
