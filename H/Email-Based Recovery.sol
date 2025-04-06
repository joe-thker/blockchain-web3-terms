contract EmailRecoveryWallet {
    address public owner;
    address public recoveryGuardian;

    constructor(address _owner, address _guardian) {
        owner = _owner;
        recoveryGuardian = _guardian;
    }

    function recoverOwnership(address newOwner) external {
        require(msg.sender == recoveryGuardian, "Not guardian");
        owner = newOwner;
    }

    function execute(address to, uint256 amount) external {
        require(msg.sender == owner, "Not owner");
        payable(to).transfer(amount);
    }

    receive() external payable {}
}
