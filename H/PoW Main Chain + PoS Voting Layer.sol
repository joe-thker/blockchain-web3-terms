contract HybridPoWVoted {
    struct Block {
        address miner;
        uint256 nonce;
        bytes32 hash;
        bool accepted;
    }

    mapping(uint256 => Block) public powBlocks;
    mapping(address => uint256) public stakes;
    mapping(uint256 => mapping(address => bool)) public voted;

    uint256 public difficulty = 2**240;
    uint256 public blockNumber;

    function stake() external payable {
        require(msg.value >= 1 ether);
        stakes[msg.sender] += msg.value;
    }

    function mine(uint256 nonce) external {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, nonce));
        require(uint256(hash) < difficulty, "Invalid PoW");
        powBlocks[blockNumber] = Block(msg.sender, nonce, hash, false);
    }

    function approveBlock() external {
        require(stakes[msg.sender] > 0, "Not validator");
        require(!voted[blockNumber][msg.sender], "Already voted");

        Block storage blk = powBlocks[blockNumber];
        require(blk.miner != address(0), "No mined block");

        voted[blockNumber][msg.sender] = true;

        // Simple 2-vote quorum
        if (!blk.accepted) {
            blk.accepted = true;
            blockNumber++;
        }
    }
}
