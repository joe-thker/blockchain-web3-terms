contract ModularExecutionLayer {
    address public consensusLayer;
    mapping(bytes32 => bool) public validated;

    constructor(address _consensus) {
        consensusLayer = _consensus;
    }

    function execute(bytes32 txHash) external {
        require(validated[txHash], "Not validated by consensus layer");
        // Execute state change (mock)
    }

    function validateFromConsensus(bytes32 txHash) external {
        require(msg.sender == consensusLayer, "Only consensus layer");
        validated[txHash] = true;
    }
}
