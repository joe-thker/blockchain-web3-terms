contract MultiSecretHTLC {
    address public recipient;
    bytes32 public hash1;
    bytes32 public hash2;
    uint256 public expiry;
    bool public claimed;

    constructor(
        address _recipient,
        bytes32 _hash1,
        bytes32 _hash2,
        uint256 _duration
    ) payable {
        require(msg.value > 0);
        recipient = _recipient;
        hash1 = _hash1;
        hash2 = _hash2;
        expiry = block.timestamp + _duration;
    }

    function claim(bytes32 _secret1, bytes32 _secret2) external {
        require(!claimed);
        require(msg.sender == recipient);
        require(keccak256(abi.encodePacked(_secret1)) == hash1);
        require(keccak256(abi.encodePacked(_secret2)) == hash2);

        claimed = true;
        payable(recipient).transfer(address(this).balance);
    }

    function refund(address payable to) external {
        require(block.timestamp >= expiry);
        require(!claimed);
        to.transfer(address(this).balance);
    }
}
