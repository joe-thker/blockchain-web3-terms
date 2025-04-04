contract RefundExample {
    uint256 public data = 123;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function clearStorage() external {
        require(msg.sender == owner, "Only owner");
        delete data; // triggers gas refund
    }

    function destroy() external {
        require(msg.sender == owner, "Only owner");
        selfdestruct(payable(msg.sender)); // triggers gas refund
    }
}
