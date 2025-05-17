// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
}

contract WannaCryRansom {
    address public immutable token;
    address public immutable attacker;
    mapping(address => bool) public locked;
    mapping(address => uint256) public ransomOwed;

    event Infected(address indexed victim, uint256 ransom);
    event RansomPaid(address indexed victim, uint256 amount);
    event Released(address indexed victim);

    constructor(address _token, address _attacker) {
        token = _token;
        attacker = _attacker;
    }

    function infect(address victim, uint256 amount) external {
        require(!locked[victim], "Already infected");
        locked[victim] = true;
        ransomOwed[victim] = amount;
        emit Infected(victim, amount);
    }

    function payRansom() external {
        require(locked[msg.sender], "Not infected");
        uint256 ransom = ransomOwed[msg.sender];

        bool ok = IERC20(token).transferFrom(msg.sender, attacker, ransom);
        require(ok, "Payment failed");

        locked[msg.sender] = false;
        ransomOwed[msg.sender] = 0;
        emit RansomPaid(msg.sender, ransom);
        emit Released(msg.sender);
    }

    function isInfected(address victim) external view returns (bool) {
        return locked[victim];
    }
}
