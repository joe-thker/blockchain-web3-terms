// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GSN_OpenGSN {
    address public trustedForwarder;
    mapping(address => uint256) public actions;

    constructor(address _forwarder) {
        trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address fwd) public view returns (bool) {
        return fwd == trustedForwarder;
    }

    function _msgSender() internal view returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender = msg.sender;
        }
    }

    function act() external {
        address user = _msgSender();
        actions[user]++;
    }
}
