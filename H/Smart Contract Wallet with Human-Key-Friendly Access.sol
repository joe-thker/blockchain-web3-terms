contract HumanKeySmartWallet {
    address public primary;
    address public recovery;
    bool public locked;

    constructor(address _primary, address _recovery) {
        primary = _primary;
        recovery = _recovery;
    }

    modifier onlyPrimary() {
        require(msg.sender == primary, "Not primary");
        _;
    }

    function lockWallet() external onlyPrimary {
        locked = true;
    }

    function unlockWallet() external {
        require(msg.sender == recovery, "Not recovery");
        locked = false;
    }

    function execute(address to, uint256 amount) external onlyPrimary {
        require(!locked, "Wallet is locked");
        payable(to).transfer(amount);
    }

    receive() external payable {}
}
