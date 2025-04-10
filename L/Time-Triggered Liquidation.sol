contract TimeBasedLiquidation {
    struct Loan {
        uint256 collateral;
        uint256 deadline;
    }

    mapping(address => Loan) public loans;

    function openLoan(uint256 duration) external payable {
        loans[msg.sender] = Loan(msg.value, block.timestamp + duration);
    }

    function liquidate(address borrower) external {
        require(block.timestamp > loans[borrower].deadline, "Still active");
        delete loans[borrower];
        // Collateral goes to liquidator
    }
}
