contract RIPEMD160Example {
    function hash(string memory input) external pure returns (bytes20) {
        return ripemd160(abi.encodePacked(input));
    }
}
