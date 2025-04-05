contract FlashLoanAttack {
    address lendingPool;

    constructor(address _pool) {
        lendingPool = _pool;
    }

    function executeAttack() external {
        // flashLoan → manipulate token price → profit → repay
    }
}
