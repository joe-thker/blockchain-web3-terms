// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TokenSetsModule - Simplified Set Protocol Simulation (ERC20 Basket + Manager)

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

/// 🧺 ERC20 Basket Token
contract SetToken {
    string public name = "Set Portfolio Token";
    string public symbol = "SET";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public manager;

    mapping(address => uint256) public balances;

    IERC20 public tokenA; // e.g., WETH
    IERC20 public tokenB; // e.g., USDC

    uint256 public ratioA = 1e18;  // 1 unit of tokenA
    uint256 public ratioB = 1000e6; // 1000 units of tokenB

    modifier onlyManager() {
        require(msg.sender == manager, "Not manager");
        _;
    }

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        manager = msg.sender;
    }

    function mint(uint256 amt) external {
        uint256 reqA = (amt * ratioA) / 1e18;
        uint256 reqB = (amt * ratioB) / 1e18;

        require(tokenA.transferFrom(msg.sender, address(this), reqA), "A fail");
        require(tokenB.transferFrom(msg.sender, address(this), reqB), "B fail");

        balances[msg.sender] += amt;
        totalSupply += amt;
    }

    function redeem(uint256 amt) external {
        require(balances[msg.sender] >= amt, "Low balance");

        balances[msg.sender] -= amt;
        totalSupply -= amt;

        uint256 outA = (amt * ratioA) / 1e18;
        uint256 outB = (amt * ratioB) / 1e18;

        require(tokenA.transfer(msg.sender, outA), "A out fail");
        require(tokenB.transfer(msg.sender, outB), "B out fail");
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    // Rebalance changes the required backing per SET token
    function rebalance(uint256 newRatioA, uint256 newRatioB) external onlyManager {
        ratioA = newRatioA;
        ratioB = newRatioB;
    }
}

/// ⚖️ Rebalance Manager Example (e.g., RSI/Momentum)
contract RSIRebalanceManager {
    SetToken public set;
    uint256 public callCount;

    constructor(address _set) {
        set = SetToken(_set);
    }

    function trigger() external {
        callCount++;
        // alternate: ETH-heavy or USDC-heavy
        if (callCount % 2 == 0) {
            set.rebalance(2e18, 500e6); // 2 ETH, 500 USDC
        } else {
            set.rebalance(1e18, 1000e6); // back to original
        }
    }
}

/// 🔓 Set Attacker (Mint Abuse or Redeem Exploit)
interface ISetToken {
    function mint(uint256) external;
    function redeem(uint256) external;
}

contract SetAttacker {
    function tryReenterMint(ISetToken set, uint256 amt) external {
        set.mint(amt);
        set.redeem(amt); // may try to break internal accounting
    }
}
