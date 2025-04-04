contract MultiSigGovernance {
    address[] public owners;
    uint256 public threshold;

    mapping(bytes32 => uint256) public votes;
    mapping(bytes32 => bool) public executed;

    constructor(address[] memory _owners, uint256 _threshold) {
        owners = _owners;
        threshold = _threshold;
    }

    function voteProposal(bytes32 proposalHash) external {
        require(isOwner(msg.sender), "Not owner");
        require(!executed[proposalHash], "Already executed");
        votes[proposalHash]++;
        if (votes[proposalHash] >= threshold) {
            executed[proposalHash] = true;
            // execute proposal logic...
        }
    }

    function isOwner(address user) public view returns (bool) {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == user) return true;
        }
        return false;
    }
}
