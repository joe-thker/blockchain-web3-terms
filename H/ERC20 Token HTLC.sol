import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20HTLC {
    address public sender;
    address public recipient;
    bytes32 public hashLock;
    uint256 public expiry;
    bool public claimed;

    IERC20 public token;
    uint256 public amount;

    constructor(
        address _token,
        address _recipient,
        bytes32 _hashLock,
        uint256 _amount,
        uint256 _duration
    ) {
        sender = msg.sender;
        token = IERC20(_token);
        recipient = _recipient;
        hashLock = _hashLock;
        amount = _amount;
        expiry = block.timestamp + _duration;

        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
    }

    function claim(bytes32 _secret) external {
        require(!claimed, "Already claimed");
        require(msg.sender == recipient, "Not recipient");
        require(keccak256(abi.encodePacked(_secret)) == hashLock, "Wrong secret");

        claimed = true;
        token.transfer(msg.sender, amount);
    }

    function refund() external {
        require(block.timestamp >= expiry, "Too early");
        require(!claimed, "Already claimed");
        require(msg.sender == sender, "Not sender");

        token.transfer(sender, amount);
    }
}
