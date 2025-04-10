// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title LeverageTokenTypes
/// @notice Examples of different leverage token designs in Solidity

/// 1. Fixed Leverage Token (e.g., 2x Long)
contract FixedLeverageToken is ERC20, Ownable {
    address public collateralAsset;
    uint256 public leverageFactor = 2;

    constructor(address _collateral) ERC20("2x Long Token", "L2X") Ownable(msg.sender) {
        collateralAsset = _collateral;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

/// 2. Short Leverage Token (e.g., -3x)
contract ShortLeverageToken is ERC20, Ownable {
    address public collateralAsset;
    int256 public leverageFactor = -3;

    constructor(address _collateral) ERC20("-3x Short Token", "S3X") Ownable(msg.sender) {
        collateralAsset = _collateral;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

/// 3. Dynamic Leverage Token
contract DynamicLeverageToken is ERC20, Ownable {
    address public collateralAsset;
    uint256 public currentLeverage;

    constructor(address _collateral, uint256 initialLeverage) ERC20("Dynamic Leverage Token", "DLT") Ownable(msg.sender) {
        collateralAsset = _collateral;
        currentLeverage = initialLeverage;
    }

    function updateLeverage(uint256 newLeverage) external onlyOwner {
        currentLeverage = newLeverage;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

/// 4. Rebalancing Leverage Token (simulated logic)
contract RebalancingLeverageToken is ERC20, Ownable {
    uint256 public lastRebalance;
    uint256 public rebalanceInterval = 1 days;

    constructor() ERC20("Rebalancing Token", "RBL") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function rebalance() external {
        require(block.timestamp >= lastRebalance + rebalanceInterval, "Too soon");
        lastRebalance = block.timestamp;
        // Simulate rebalance logic: price readjustment, supply adjust
    }
}

/// 5. Collateralized Leverage Token (simplified)
contract CollateralizedLeverageToken is ERC20, Ownable {
    mapping(address => uint256) public deposits;
    uint256 public leverage = 3;

    constructor() ERC20("Collateral Leverage Token", "CLT") Ownable(msg.sender) {}

    function deposit() external payable {
        require(msg.value > 0, "No ETH");
        uint256 minted = msg.value * leverage;
        _mint(msg.sender, minted);
        deposits[msg.sender] += msg.value;
    }

    function withdraw(uint256 tokenAmount) external {
        require(balanceOf(msg.sender) >= tokenAmount, "Insufficient balance");
        uint256 collateral = tokenAmount / leverage;
        require(deposits[msg.sender] >= collateral, "Too much");
        _burn(msg.sender, tokenAmount);
        deposits[msg.sender] -= collateral;
        payable(msg.sender).transfer(collateral);
    }

    receive() external payable {}
}
