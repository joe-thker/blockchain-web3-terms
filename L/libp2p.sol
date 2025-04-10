// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title libp2p Node Identity Registry
/// @notice Registers off-chain peer IDs + metadata for on-chain identity reference
contract Libp2pRegistry {
    struct PeerInfo {
        string peerId;
        string multiAddr;
        string protocol;
        uint256 registeredAt;
    }

    mapping(address => PeerInfo) public peers;

    event Registered(address indexed node, string peerId, string multiAddr, string protocol);

    function registerNode(string calldata peerId, string calldata multiAddr, string calldata protocol) external {
        peers[msg.sender] = PeerInfo({
            peerId: peerId,
            multiAddr: multiAddr,
            protocol: protocol,
            registeredAt: block.timestamp
        });

        emit Registered(msg.sender, peerId, multiAddr, protocol);
    }

    function getNode(address node) external view returns (PeerInfo memory) {
        return peers[node];
    }
}
