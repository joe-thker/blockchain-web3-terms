contract GSN_Biconomy {
    mapping(address => uint256) public nonce;
    mapping(address => uint256) public actions;

    function executeMetaTx(address user, uint256 nonce_, bytes calldata sig) external {
        bytes32 hash = keccak256(abi.encodePacked(user, nonce_));
        require(recover(hash, sig) == user, "Invalid sig");
        require(nonce[user] == nonce_, "Invalid nonce");

        nonce[user]++;
        actions[user]++;
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
