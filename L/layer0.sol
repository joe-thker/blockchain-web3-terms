// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Layer 0 Message Receiver Simulator
contract Layer0Bridge {
    event MessageReceived(uint16 sourceChainId, address sourceSender, string payload);
    mapping(uint16 => address) public trustedSources;

    modifier onlyTrustedSource(uint16 _chainId) {
        require(msg.sender == trustedSources[_chainId], "Untrusted source");
        _;
    }

    function setTrustedSource(uint16 _chainId, address _source) external {
        trustedSources[_chainId] = _source;
    }

    // Simulates incoming cross-chain message from a Layer 1
    function receiveMessage(uint16 _srcChainId, address _srcSender, string calldata _payload)
        external
        onlyTrustedSource(_srcChainId)
    {
        emit MessageReceived(_srcChainId, _srcSender, _payload);
        // Further logic like token minting, voting, etc. could follow here.
    }
}
