contract HybridParallel {
    struct Candidate {
        address miner;
        address validator;
        bytes32 hash;
        bool valid;
    }

    mapping(uint256 => Candidate) public blocks;
    uint256 public height;

    function submitProof(address validator, uint256 nonce) external {
        require(tx.origin != address(0), "Invalid origin");

        bytes32 hash = keccak256(abi.encodePacked(msg.sender, nonce));
        require(uint256(hash) < 2**240, "Hash too high");

        blocks[height] = Candidate(msg.sender, validator, hash, true);
        height++;
    }

    function getBlock(uint256 id) external view returns (Candidate memory) {
        return blocks[id];
    }
}
