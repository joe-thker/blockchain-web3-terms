contract ValidatorDAG {
    mapping(address => bool) public isValidator;
    mapping(bytes32 => bytes32[]) public eventParents;

    modifier onlyValidator() {
        require(isValidator[msg.sender], "Not validator");
        _;
    }

    constructor(address[] memory validators) {
        for (uint i = 0; i < validators.length; i++) {
            isValidator[validators[i]] = true;
        }
    }

    function createEvent(bytes32[] memory parents) external onlyValidator returns (bytes32) {
        bytes32 hash = keccak256(abi.encode(msg.sender, block.timestamp, parents));
        eventParents[hash] = parents;
        return hash;
    }
}
