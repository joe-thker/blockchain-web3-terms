contract HashChallenge {
    bytes32 public constant secretHash = keccak256(abi.encodePacked("solidity"));

    function solve(string memory guess) external pure returns (bool) {
        return keccak256(abi.encodePacked(guess)) == secretHash;
    }
}
