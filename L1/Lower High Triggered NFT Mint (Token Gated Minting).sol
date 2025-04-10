contract LowerHighNFTMinter {
    uint256 public lastHigh = type(uint256).max;
    mapping(address => bool) public minted;

    function submitHighAndMint(uint256 newHigh) external {
        require(newHigh < lastHigh, "Not a lower high");
        require(!minted[msg.sender], "Already minted");

        lastHigh = newHigh;
        minted[msg.sender] = true;

        // Simulate mint
        emit Minted(msg.sender);
    }

    event Minted(address indexed user);
}
