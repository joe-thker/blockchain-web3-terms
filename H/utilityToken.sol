// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title UtilityToken - Designed to avoid Howey Test violation
contract UtilityToken is ERC20 {
    constructor() ERC20("AccessToken", "ACCESS") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    /// @notice Pure utility: Access to dApp, no profit sharing, no staking
    function accessService() external view returns (string memory) {
        require(balanceOf(msg.sender) > 0, "Access denied");
        return "Welcome to the utility service!";
    }
}
