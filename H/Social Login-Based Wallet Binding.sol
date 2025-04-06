contract SocialLoginWallet {
    mapping(bytes32 => address) public linkedWallets;

    function linkWallet(string calldata oauthID) external {
        bytes32 idHash = keccak256(abi.encodePacked(oauthID));
        linkedWallets[idHash] = msg.sender;
    }

    function resolveWallet(string calldata oauthID) external view returns (address) {
        return linkedWallets[keccak256(abi.encodePacked(oauthID))];
    }
}
