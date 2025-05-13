// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TransactionTriggerModule - Time + Price Based Trigger Execution

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
}

/// 🧠 Price Oracle (Mock)
contract PriceOracle {
    mapping(address => uint256) public prices;

    function setPrice(address token, uint256 price) external {
        prices[token] = price;
    }

    function getPrice(address token) external view returns (uint256) {
        return prices[token];
    }
}

/// ⏳ Time & Price Trigger Vault
contract TriggerVault {
    address public token;
    PriceOracle public oracle;
    address public keeper;
    uint256 public unlockTime;
    uint256 public priceThreshold;
    bool public executed;

    event TriggerExecuted(address indexed keeper, uint256 value);

    constructor(address _token, address _oracle, address _keeper, uint256 _delay, uint256 _price) {
        token = _token;
        oracle = PriceOracle(_oracle);
        keeper = _keeper;
        unlockTime = block.timestamp + _delay;
        priceThreshold = _price;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper, "Not keeper");
        _;
    }

    function trigger() external onlyKeeper {
        require(!executed, "Already executed");
        require(block.timestamp >= unlockTime, "Too early");
        uint256 price = oracle.getPrice(token);
        require(price >= priceThreshold, "Price too low");

        executed = true;
        emit TriggerExecuted(msg.sender, price);
    }
}

/// 🧑‍🔧 Trigger Keeper (Off-chain or DAO)
interface ITriggerVault {
    function trigger() external;
}

contract TriggerKeeper {
    function activate(ITriggerVault vault) external {
        vault.trigger(); // Called from bot or scheduled keeper
    }
}

/// 🔓 Trigger Attacker (Spoof Oracle + Re-trigger)
interface IPriceOracle {
    function setPrice(address, uint256) external;
}

contract TriggerAttacker {
    function spoof(IPriceOracle oracle, address token, uint256 fakePrice) external {
        oracle.setPrice(token, fakePrice); // Abuses price for early trigger
    }

    function duplicate(ITriggerVault vault) external {
        vault.trigger(); // Replay attempt
    }
}
