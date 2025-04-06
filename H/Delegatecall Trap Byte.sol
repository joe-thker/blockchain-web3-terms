contract LogicV1 {
    // Simulate legit logic
    function run() external pure returns (uint256) {
        return 42;
    }
}

contract HostageLogic {
    fallback() external payable {
        revert("Gotcha - delegatecall trap!");
    }
}

contract Proxy {
    address public logic;

    constructor(address _logic) {
        logic = _logic;
    }

    function execute(bytes calldata data) external returns (bytes memory) {
        (bool success, bytes memory result) = logic.delegatecall(data);
        require(success, "Hostage byte triggered");
        return result;
    }
}
