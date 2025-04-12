// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FUDsterEarn is ERC20, Ownable {
    mapping(address => uint256) public reputation;
    mapping(address => uint256) public fudsPosted;

    uint256 public constant REWARD = 10 * 1e18;
    uint256 public constant REPUTATION_PENALTY = 5;

    event FUDDropped(address indexed sender, string message);

    constructor(address initialOwner) ERC20("FUDster Token", "FUDS") Ownable(initialOwner) {
        _mint(initialOwner, 100_000 * 1e18);
        reputation[initialOwner] = 100;
    }

    function spreadFUD(string calldata message) external {
        require(bytes(message).length > 4, "Too short");

        fudsPosted[msg.sender]++;
        reputation[msg.sender] = reputation[msg.sender] > REPUTATION_PENALTY
            ? reputation[msg.sender] - REPUTATION_PENALTY
            : 0;

        _mint(msg.sender, REWARD);
        emit FUDDropped(msg.sender, message);
    }

    function getFUDsterStats(address user) external view returns (
        uint256 rep,
        uint256 totalFUDs
    ) {
        return (reputation[user], fudsPosted[user]);
    }
}
