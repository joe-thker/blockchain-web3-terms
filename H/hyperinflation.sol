// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title HyperInflationToken - Token with uncontrolled inflation
contract HyperInflationToken is ERC20 {
    address public admin;

    constructor() ERC20("HyperToken", "HYPE") {
        admin = msg.sender;
        _mint(msg.sender, 1000 * 1e18); // Initial small supply
    }

    /// @notice Mint new tokens rapidly - simulating inflation
    function hyperInflate() external {
        require(msg.sender == admin, "Only admin can inflate");

        uint256 excessiveAmount = totalSupply() * 10; // 1000% inflation
        _mint(admin, excessiveAmount); // Hyperinflate
    }
}
