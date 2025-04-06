contract HybridPoSSelect {
    struct BlockProposal {
        address miner;
        uint256 nonce;
        bytes32 hash;
    }

    mapping(uint256 => BlockProposal[]) public proposals;
    mapping(address => uint256) public stakes;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => address) public selectedBlock;

    uint256 public difficulty = 2**240;
    uint256 public height;

    function stake() external payable {
        require(msg.value >= 1 ether);
        stakes[msg.sender] += msg.value;
    }

    function propose(uint256 nonce) external {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, nonce));
        require(uint256(hash) < difficulty);
        proposals[height].push(BlockProposal(msg.sender, nonce, hash));
    }

    function vote(uint256 index) external {
        require(stakes[msg.sender] > 0);
        require(!hasVoted[height][msg.sender]);
        hasVoted[height][msg.sender] = true;

        BlockProposal memory choice = proposals[height][index];
        selectedBlock[height] = choice.miner;

        height++;
    }

    function getSelectedMiner(uint256 id) external view returns (address) {
        return selectedBlock[id];
    }
}
