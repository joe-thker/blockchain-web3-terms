contract FallbackTrap {
    address public owner = msg.sender;

    fallback() external payable {
        payable(owner).transfer(msg.value);
    }

    receive() external payable {
        payable(owner).transfer(msg.value);
    }
}
