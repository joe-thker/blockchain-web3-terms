contract FinalityDAG {
    uint256 public threshold;
    mapping(bytes32 => uint256) public voteCount;
    mapping(bytes32 => bool) public finalized;

    constructor(uint256 _threshold) {
        threshold = _threshold;
    }

    function vote(bytes32 hash) external {
        require(!finalized[hash], "Already finalized");
        voteCount[hash]++;
        if (voteCount[hash] >= threshold) {
            finalized[hash] = true;
        }
    }

    function isFinalized(bytes32 hash) external view returns (bool) {
        return finalized[hash];
    }
}
