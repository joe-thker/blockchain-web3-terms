// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LiquidationBackstop is Ownable {
    IERC20 public token;
    address public lendingProtocol;

    constructor(IERC20 _token, address _lendingProtocol) Ownable(msg.sender) {
        token = _token;
        lendingProtocol = _lendingProtocol;
    }

    modifier onlyProtocol() {
        require(msg.sender == lendingProtocol, "Unauthorized");
        _;
    }

    function coverShortfall(address user, uint256 amount) external onlyProtocol {
        token.transfer(user, amount);
    }

    function fund(uint256 amount) external onlyOwner {
        token.transferFrom(msg.sender, address(this), amount);
    }
}
