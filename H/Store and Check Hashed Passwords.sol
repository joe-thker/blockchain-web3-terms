contract HashedPasswordVault {
    bytes32 private hashedSecret;

    constructor(string memory secret) {
        hashedSecret = keccak256(abi.encodePacked(secret));
    }

    function checkSecret(string memory guess) external view returns (bool) {
        return keccak256(abi.encodePacked(guess)) == hashedSecret;
    }
}
