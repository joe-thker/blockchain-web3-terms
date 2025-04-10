// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Leveraged Token Simulator (3x Long)
contract LeveragedToken {
    address public admin;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    uint256 public price; // Simulated underlying price
    uint256 public lastPrice;

    event Minted(address indexed user, uint256 amount);
    event Burned(address indexed user, uint256 amount);
    event Rebalanced(uint256 priceChange, int256 pnl);

    constructor(uint256 _initialPrice) {
        admin = msg.sender;
        price = _initialPrice;
        lastPrice = _initialPrice;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    function mint(uint256 amount) external {
        balances[msg.sender] += amount;
        totalSupply += amount;
        emit Minted(msg.sender, amount);
    }

    function burn(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        emit Burned(msg.sender, amount);
    }

    /// @notice Admin updates price and rebalances 3x long position
    function rebalance(uint256 newPrice) external onlyAdmin {
        require(newPrice > 0, "Invalid price");
        int256 change = int256(newPrice) - int256(lastPrice);
        int256 pctChange = (change * 100) / int256(lastPrice); // e.g., +5%
        int256 leverageEffect = pctChange * 3; // 3x leverage

        int256 pnl = (int256(totalSupply) * leverageEffect) / 100;
        if (pnl > 0) {
            totalSupply += uint256(pnl);
        } else {
            totalSupply -= uint256(-pnl);
        }

        lastPrice = newPrice;
        emit Rebalanced(uint256(pctChange), pnl);
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}
