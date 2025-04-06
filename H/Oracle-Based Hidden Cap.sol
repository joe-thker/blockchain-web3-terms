interface ICapOracle {
    function getCap() external view returns (uint256);
}

contract OracleHiddenCap {
    address public owner;
    address public oracle;
    uint256 public totalRaised;

    constructor(address _oracle) {
        owner = msg.sender;
        oracle = _oracle;
    }

    receive() external payable {
        uint256 cap = ICapOracle(oracle).getCap();
        require(totalRaised + msg.value <= cap, "Oracle cap exceeded");
        totalRaised += msg.value;
    }

    function withdraw() external {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }
}
