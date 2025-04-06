interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract TokenHODLVault {
    address public owner;
    IERC20 public token;
    uint256 public unlockTime;
    uint256 public lockedAmount;

    constructor(address _token, uint256 _amount, uint256 _duration) {
        owner = msg.sender;
        token = IERC20(_token);
        unlockTime = block.timestamp + _duration;

        require(token.transferFrom(owner, address(this), _amount), "Transfer failed");
        lockedAmount = _amount;
    }

    function release() external {
        require(msg.sender == owner, "Not owner");
        require(block.timestamp >= unlockTime, "Still locked");

        token.transfer(owner, lockedAmount);
        lockedAmount = 0;
    }
}
