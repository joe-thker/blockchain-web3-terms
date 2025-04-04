contract GSN_SelfRelay {
    mapping(address => uint256) public nonce;

    function relayAndExecute(address user, bytes calldata data, uint256 nonce_, bytes calldata sig) external {
        require(nonce[user] == nonce_, "Bad nonce");

        bytes32 hash = keccak256(abi.encodePacked(user, data, nonce_));
        require(recover(hash, sig) == user, "Bad sig");

        nonce[user]++;

        // Forward call to this contract
        (bool success, ) = address(this).call(abi.encodePacked(data, user));
        require(success, "Relay failed");
    }

    function dummyAction(address realUser) external {
        // Called via relay
        require(msg.sender == address(this));
        // use realUser instead of msg.sender
    }

    function recover(bytes32 hash, bytes memory sig) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = split(sig);
        return ecrecover(hash, v, r, s);
    }

    function split(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
