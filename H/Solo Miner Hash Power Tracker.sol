contract SoloHashPower {
    mapping(address => uint256) public hashPower;

    function submitHash(uint256 amount) external {
        require(amount > 0, "Must submit some hash work");
        hashPower[msg.sender] += amount;
    }

    function getMyHashPower() external view returns (uint256) {
        return hashPower[msg.sender];
    }
}
