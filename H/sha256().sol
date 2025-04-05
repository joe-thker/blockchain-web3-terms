contract SHA256Example {
    function hash(string memory input) external pure returns (bytes32) {
        return sha256(abi.encodePacked(input));
    }
}
