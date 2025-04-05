contract TokenV2 {
    string public name = "HardForkedToken";
    mapping(address => uint256) public balances;

    function mint() external {
        balances[msg.sender] += 200; // Hard fork increases reward
    }

    function getVersion() external pure returns (string memory) {
        return "V2";
    }
}
