// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ContractForDifference
/// @notice A simplified Contract for Difference (CFD) between two parties (long and short).
/// Each party deposits collateral and agrees on an opening price and notional quantity.
/// Later, an authorized party settles the CFD with a closing price, and funds are transferred based on the price difference.
contract ContractForDifference is Ownable, ReentrancyGuard {
    // Parties involved.
    address public longParty;
    address public shortParty;

    // Opening price (scaled, e.g. 1e18 scaling factor) and notional quantity.
    uint256 public openingPrice;
    uint256 public quantity;

    // Collateral deposited by each party (in wei).
    uint256 public longCollateral;
    uint256 public shortCollateral;

    // Settlement price.
    uint256 public closingPrice;

    // Contract state.
    enum State { Initialized, Active, Settled, Liquidated }
    State public state;

    // Events.
    event CFDInitialized(address indexed longParty, address indexed shortParty, uint256 openingPrice, uint256 quantity);
    event CollateralDeposited(address indexed party, uint256 amount);
    event Activated();
    event Settled(uint256 closingPrice, uint256 longPayout, uint256 shortPayout);
    event Liquidated(address indexed party);

    /// @notice Initializes the CFD with the two parties, an opening price, and notional quantity.
    /// Both parties must then deposit collateral before the contract can be activated.
    /// @param _longParty Address of the long party.
    /// @param _shortParty Address of the short party.
    /// @param _openingPrice The agreed opening price (scaled).
    /// @param _quantity The notional quantity.
    constructor(
        address _longParty,
        address _shortParty,
        uint256 _openingPrice,
        uint256 _quantity
    ) Ownable(msg.sender) {
        require(_longParty != address(0) && _shortParty != address(0), "Invalid party address");
        require(_openingPrice > 0, "Opening price must be positive");
        require(_quantity > 0, "Quantity must be positive");

        longParty = _longParty;
        shortParty = _shortParty;
        openingPrice = _openingPrice;
        quantity = _quantity;
        state = State.Initialized;

        emit CFDInitialized(_longParty, _shortParty, _openingPrice, _quantity);
    }

    /// @notice Allows either party to deposit collateral.
    /// Each party calls this function (sending Ether) to deposit collateral.
    function depositCollateral() external payable nonReentrant {
        require(state == State.Initialized, "Collateral deposit closed");
        require(msg.value > 0, "Deposit must be > 0");

        if (msg.sender == longParty) {
            longCollateral += msg.value;
            emit CollateralDeposited(msg.sender, msg.value);
        } else if (msg.sender == shortParty) {
            shortCollateral += msg.value;
            emit CollateralDeposited(msg.sender, msg.value);
        } else {
            revert("Not a CFD party");
        }
    }

    /// @notice Activates the CFD once both parties have deposited collateral.
    /// Can be called by either party.
    function activate() external nonReentrant {
        require(state == State.Initialized, "Already activated or settled");
        require(longCollateral > 0 && shortCollateral > 0, "Both parties must deposit collateral");
        state = State.Active;
        emit Activated();
    }

    /// @notice Settles the CFD with a closing price.
    /// Only the owner (or designated oracle) can call this.
    /// @param _closingPrice The closing price (scaled).
    function settle(uint256 _closingPrice) external onlyOwner nonReentrant {
        require(state == State.Active, "CFD not active");
        require(_closingPrice > 0, "Closing price must be positive");

        closingPrice = _closingPrice;
        state = State.Settled;

        // Calculate price difference and profit/loss.
        // profit = (closingPrice - openingPrice) * quantity.
        int256 priceDiff = int256(closingPrice) - int256(openingPrice);
        int256 profit = priceDiff * int256(quantity);

        uint256 longPayout;
        uint256 shortPayout;

        if (profit > 0) {
            // Long party wins; profit amount is taken from short's collateral.
            uint256 profitAmount = uint256(profit);
            if (profitAmount > shortCollateral) {
                // Short party cannot cover the loss; liquidate short.
                longPayout = longCollateral + shortCollateral;
                shortPayout = 0;
                state = State.Liquidated;
                emit Liquidated(shortParty);
            } else {
                longPayout = longCollateral + profitAmount;
                shortPayout = shortCollateral - profitAmount;
            }
        } else if (profit < 0) {
            // Short party wins; loss for long is profit for short.
            uint256 lossAmount = uint256(-profit);
            if (lossAmount > longCollateral) {
                // Long party cannot cover the loss; liquidate long.
                shortPayout = shortCollateral + longCollateral;
                longPayout = 0;
                state = State.Liquidated;
                emit Liquidated(longParty);
            } else {
                shortPayout = shortCollateral + lossAmount;
                longPayout = longCollateral - lossAmount;
            }
        } else {
            // No profit, no loss.
            longPayout = longCollateral;
            shortPayout = shortCollateral;
        }

        // Transfer payouts.
        if (longPayout > 0) {
            (bool successLong, ) = longParty.call{value: longPayout}("");
            require(successLong, "Transfer to long party failed");
        }
        if (shortPayout > 0) {
            (bool successShort, ) = shortParty.call{value: shortPayout}("");
            require(successShort, "Transfer to short party failed");
        }

        emit Settled(_closingPrice, longPayout, shortPayout);
    }

    /// @notice Fallback function to receive Ether.
    receive() external payable {}
}
