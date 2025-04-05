contract MerkleProofVerifier {
    bytes32 public merkleRoot;

    constructor(bytes32 _root) {
        merkleRoot = _root;
    }

    function verifyLeaf(bytes32 leaf, bytes32[] calldata proof) external view returns (bool) {
        bytes32 hash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            hash = keccak256(abi.encodePacked(hash, proof[i]));
        }
        return hash == merkleRoot;
    }
}
