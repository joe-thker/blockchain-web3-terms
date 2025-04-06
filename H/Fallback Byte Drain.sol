contract FallbackByteTrap {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    fallback() external payable {
        if (msg.data.length > 0 && msg.data[msg.data.length - 1] == 0x99) {
            revert("Malicious byte triggered");
        }
    }

    receive() external payable {}
}
