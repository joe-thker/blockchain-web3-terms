// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TradingViewModule - Trading Signal Execution from Trusted Relayer

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

/// 📡 Signal Vault - Executes only on Verified Signal
contract SignalVault {
    address public token;
    address public trustedRelayer;
    bool public signalTriggered;
    uint256 public lastSignalBlock;

    event TradeExecuted(address indexed user, uint256 amount);

    constructor(address _token, address _relayer) {
        token = _token;
        trustedRelayer = _relayer;
    }

    modifier onlyRelayer() {
        require(msg.sender == trustedRelayer, "Not relayer");
        _;
    }

    function triggerSignal() external onlyRelayer {
        signalTriggered = true;
        lastSignalBlock = block.number;
    }

    function tradeOnSignal(uint256 amt) external {
        require(signalTriggered, "Signal not triggered");
        require(block.number <= lastSignalBlock + 5, "Signal expired");

        IERC20(token).transferFrom(msg.sender, address(this), amt);
        signalTriggered = false;

        emit TradeExecuted(msg.sender, amt);
    }
}

/// 📈 RSI Indicator (Simplified On-Chain Calculation)
contract RSIIndicator {
    mapping(address => uint256[]) public priceHistory;
    mapping(address => uint256) public lastRSI;

    function updatePrice(address asset, uint256 price) external {
        priceHistory[asset].push(price);
        if (priceHistory[asset].length >= 15) {
            calculateRSI(asset);
        }
    }

    function calculateRSI(address asset) internal {
        uint256 len = priceHistory[asset].length;
        uint256 gain; uint256 loss;

        for (uint256 i = len - 14; i < len - 1; i++) {
            int256 delta = int256(priceHistory[asset][i + 1]) - int256(priceHistory[asset][i]);
            if (delta > 0) gain += uint256(delta);
            else loss += uint256(-delta);
        }

        if (loss == 0) {
            lastRSI[asset] = 100;
        } else {
            uint256 rs = gain * 100 / loss;
            lastRSI[asset] = 100 - (10000 / (100 + rs));
        }
    }

    function getRSI(address asset) external view returns (uint256) {
        return lastRSI[asset];
    }
}

/// 🌐 Signal Relayer (Simulates TradingView Webhook)
interface ISignalVault {
    function triggerSignal() external;
}

contract SignalRelayer {
    ISignalVault public vault;

    constructor(address _vault) {
        vault = ISignalVault(_vault);
    }

    function sendWebhook(bytes calldata authKey) external {
        require(authKey.length > 4, "Invalid signature");
        vault.triggerSignal();
    }
}

/// 🔓 Signal Attacker (Spoof Relay)
interface IVault {
    function triggerSignal() external;
}

contract SignalAttacker {
    function spoofSignal(IVault vault) external {
        vault.triggerSignal(); // Should fail if not whitelisted
    }
}
