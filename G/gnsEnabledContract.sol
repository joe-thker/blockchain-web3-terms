// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title GSN-Compatible Voting Contract using ERC-2771 Meta-Transactions
contract GSNVoting {
    address private trustedForwarder;

    mapping(address => uint256) public votes;

    event Voted(address indexed user, uint256 count);
    event ForwarderSet(address newForwarder);

    constructor(address _forwarder) {
        trustedForwarder = _forwarder;
        emit ForwarderSet(_forwarder);
    }

    /// @notice Set a new trusted forwarder (optional admin logic)
    function setTrustedForwarder(address _forwarder) external {
        // add access control if needed
        trustedForwarder = _forwarder;
        emit ForwarderSet(_forwarder);
    }

    /// @notice Check if address is trusted forwarder
    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == trustedForwarder;
    }

    /// @notice Internal override for msg.sender to support meta-tx
    function _msgSender() internal view returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The last 20 bytes of calldata = original sender
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender = msg.sender;
        }
    }

    /// @notice Cast a vote (can be gasless via trusted forwarder)
    function vote() external {
        address sender = _msgSender();
        votes[sender]++;
        emit Voted(sender, votes[sender]);
    }

    /// @notice View votes of any user
    function getVotes(address user) external view returns (uint256) {
        return votes[user];
    }
}
