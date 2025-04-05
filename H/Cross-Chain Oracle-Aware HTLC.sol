interface ISecretOracle {
    function getSecret() external view returns (bytes32);
}

contract OracleHTLC {
    address public recipient;
    bytes32 public hashLock;
    uint256 public expiry;
    bool public claimed;
    ISecretOracle public oracle;

    constructor(
        address _recipient,
        bytes32 _hashLock,
        uint256 _duration,
        address _oracle
    ) payable {
        require(msg.value > 0);
        recipient = _recipient;
        hashLock = _hashLock;
        expiry = block.timestamp + _duration;
        oracle = ISecretOracle(_oracle);
    }

    function claimWithOracle() external {
        require(!claimed);
        require(msg.sender == recipient);
        bytes32 oracleSecret = oracle.getSecret();
        require(keccak256(abi.encodePacked(oracleSecret)) == hashLock);

        claimed = true;
        payable(recipient).transfer(address(this).balance);
    }

    function refund() external {
        require(block.timestamp >= expiry);
        require(!claimed);
        payable(msg.sender).transfer(address(this).balance);
    }
}
