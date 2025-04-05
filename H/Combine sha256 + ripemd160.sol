contract BitcoinLikeHash {
    function pubkeyToAddress(bytes memory pubKey) external pure returns (bytes20) {
        return ripemd160(abi.encodePacked(sha256(pubKey)));
    }
}
