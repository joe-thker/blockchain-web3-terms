contract CentralizedManager {
    address public team = msg.sender;

    function generateProfit() external payable {
        require(msg.sender == team, "Only team can do this");
        // Simulated yield
    }

    function distribute() external {
        // distribute profit (manually managed)
    }
}
