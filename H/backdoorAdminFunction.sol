contract Backdoor {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function emergencyDrain(address payable to) external {
        require(msg.sender == owner, "Not owner");
        to.transfer(address(this).balance); // ⚠️ Could be abused
    }

    receive() external payable {}
}
