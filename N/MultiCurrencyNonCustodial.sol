// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MyContract
 * @notice A simple contract using OpenZeppelin's IERC20 interface.
 *         This example fetches the token balance for the caller.
 */
contract MyContract {
    IERC20 public token;

    /**
     * @dev The constructor sets the token address.
     * @param tokenAddress The address of the ERC20 token contract.
     */
    constructor(address tokenAddress) {
        require(tokenAddress != address(0), "Invalid token address");
        token = IERC20(tokenAddress);
    }

    /**
     * @notice Returns the token balance of the caller.
     * @return The token balance of the message sender.
     */
    function myTokenBalance() external view returns (uint256) {
        return token.balanceOf(msg.sender);
    }
}
