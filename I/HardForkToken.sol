// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HardForkToken is ERC20, Ownable {
    bool public forked;
    address public forkedTo;
    mapping(address => bool) public claimed;

    event ForkCreated(address newFork);
    event ForkClaimed(address user, uint256 amount);

    constructor() ERC20("HardForkToken", "HFT") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 ether);
    }

    function createFork(address newToken) external onlyOwner {
        require(!forked, "Already forked");
        forked = true;
        forkedTo = newToken;
        emit ForkCreated(newToken);
    }

    function claimFork() external {
        require(forked, "No fork");
        require(!claimed[msg.sender], "Already claimed");
        uint256 bal = balanceOf(msg.sender);
        require(bal > 0, "Nothing to claim");

        claimed[msg.sender] = true;
        HardForkToken(forkedTo).mintTo(msg.sender, bal);
        emit ForkClaimed(msg.sender, bal);
    }

    function mintTo(address to, uint256 amount) external {
        require(msg.sender == owner(), "Not fork origin");
        _mint(to, amount);
    }
}
