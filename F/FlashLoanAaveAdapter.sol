// This contract requires Aave Pool address and interface.
// For real use, use: https://docs.aave.com/developers/v/2.0/guides/flash-loans

interface IAaveFlashLoan {
    function flashLoanSimple(address receiver, address asset, uint256 amount, bytes calldata data, uint16 referralCode) external;
}

contract FlashLoanAaveAdapter {
    address public pool;

    constructor(address _aavePool) {
        pool = _aavePool;
    }

    function requestFlashLoan(address asset, uint256 amount) external {
        bytes memory data = abi.encode(msg.sender);
        IAaveFlashLoan(pool).flashLoanSimple(address(this), asset, amount, data, 0);
    }

    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata data) external returns (bool) {
        // Do custom logic (arbitrage, swap, etc.)

        // Repay
        IERC20(asset).transfer(pool, amount + premium);
        return true;
    }
}
