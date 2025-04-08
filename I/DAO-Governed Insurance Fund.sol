// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DAOInsuranceFund {
    IERC20 public token;
    address public dao;

    mapping(address => uint256) public claims;

    constructor(IERC20 _token, address _dao) {
        token = _token;
        dao = _dao;
    }

    modifier onlyDAO() {
        require(msg.sender == dao, "Not DAO");
        _;
    }

    function submitClaim(address user, uint256 amount) external onlyDAO {
        claims[user] += amount;
    }

    function claim() external {
        uint256 amount = claims[msg.sender];
        require(amount > 0, "No claim");
        claims[msg.sender] = 0;
        token.transfer(msg.sender, amount);
    }
}
