contract ProxySwap {
    address public l1Proxy;

    event L2SwapInitiated(address indexed user, uint256 amount, string reason);

    constructor(address _l1Proxy) {
        l1Proxy = _l1Proxy;
    }

    function initiateSwap(string memory reason) external payable {
        emit L2SwapInitiated(msg.sender, msg.value, reason);
        // L1 proxy handles message → executes payout
    }

    receive() external payable {}
}
