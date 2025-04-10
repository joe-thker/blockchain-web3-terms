contract SyntheticLP {
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public minted;

    function provideCollateral() external payable {
        collateral[msg.sender] += msg.value;
    }

    function mintSynthetic(uint256 amount) external {
        require(collateral[msg.sender] >= amount * 2, "Need 200% collateral");
        minted[msg.sender] += amount;
    }

    function burn(uint256 amount) external {
        minted[msg.sender] -= amount;
    }
}
