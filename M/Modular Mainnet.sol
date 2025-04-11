contract ModularMainnet {
    address public dataAvailabilityLayer;
    mapping(bytes32 => bool) public acceptedBlocks;

    constructor(address _daLayer) {
        dataAvailabilityLayer = _daLayer;
    }

    function acceptBlock(bytes32 blockHash) external {
        require(msg.sender == dataAvailabilityLayer, "Only DA layer");
        acceptedBlocks[blockHash] = true;
    }

    function isBlockValid(bytes32 blockHash) external view returns (bool) {
        return acceptedBlocks[blockHash];
    }
}
