interface IFlashLoanProvider {
    function flashLoan(uint256 amount, address target, bytes calldata data) external;
}

contract FlashLoanLiquidator {
    address public loanProvider;
    mapping(address => uint256) public debt;
    mapping(address => uint256) public collateral;

    constructor(address _provider) {
        loanProvider = _provider;
    }

    function liquidateWithFlash(address borrower, uint256 amount) external {
        bytes memory data = abi.encode(borrower, amount);
        IFlashLoanProvider(loanProvider).flashLoan(amount, address(this), data);
    }

    function executeOperation(uint256 amount, bytes calldata data) external {
        (address borrower, uint256 repayAmount) = abi.decode(data, (address, uint256));

        require(debt[borrower] >= repayAmount, "Not undercollateralized");

        // Seize collateral
        delete debt[borrower];
        delete collateral[borrower];

        // Repay flash loan
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}
