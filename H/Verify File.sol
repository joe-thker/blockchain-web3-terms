contract HashIntegrity {
    mapping(address => bytes32) public storedHashes;

    function uploadHash(bytes32 fileHash) external {
        storedHashes[msg.sender] = fileHash;
    }

    function verifyHash(bytes memory fileData) external view returns (bool) {
        return keccak256(fileData) == storedHashes[msg.sender];
    }
}
