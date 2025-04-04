interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
}

contract GSN_ERC20 {
    IERC20 public token;
    address public gasCollector;

    constructor(address _token, address _collector) {
        token = IERC20(_token);
        gasCollector = _collector;
    }

    function doAction() external {
        token.transferFrom(msg.sender, gasCollector, 1e18); // 1 token = gas cost
        // Do the action...
    }
}
