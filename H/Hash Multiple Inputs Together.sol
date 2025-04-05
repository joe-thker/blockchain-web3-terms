contract HashInputs {
    function hashPair(address user, uint256 amount) external pure returns (bytes32) {
        return keccak256(abi.encode(user, amount));
    }
}
