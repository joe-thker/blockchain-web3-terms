// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DecentralizedDerivatives
/// @notice Smart contract for dynamic decentralized derivative contracts.
contract DecentralizedDerivatives is Ownable, ReentrancyGuard {

    enum DerivativeType { Future, Option, CFD }

    struct DerivativeContract {
        uint256 id;
        DerivativeType dtype;
        string underlyingAsset;
        uint256 strikePrice;
        uint256 expirationTime;
        address creator;
        address counterparty;
        uint256 premium;
        bool active;
        bool settled;
    }

    uint256 private nextDerivativeId;
    mapping(uint256 => DerivativeContract) public derivatives;

    // Events
    event DerivativeCreated(uint256 indexed id, DerivativeType dtype, address indexed creator);
    event DerivativeJoined(uint256 indexed id, address indexed counterparty);
    event DerivativeSettled(uint256 indexed id, bool successful, uint256 payout);

    constructor() Ownable(msg.sender) {}

    /// @notice Create a new derivative dynamically
    function createDerivative(
        DerivativeType dtype,
        string calldata underlyingAsset,
        uint256 strikePrice,
        uint256 expirationTime,
        uint256 premium
    ) external payable nonReentrant {
        require(expirationTime > block.timestamp, "Expiration must be future");
        require(msg.value == premium, "Incorrect premium amount");

        uint256 id = nextDerivativeId++;
        derivatives[id] = DerivativeContract({
            id: id,
            dtype: dtype,
            underlyingAsset: underlyingAsset,
            strikePrice: strikePrice,
            expirationTime: expirationTime,
            creator: msg.sender,
            counterparty: address(0),
            premium: premium,
            active: true,
            settled: false
        });

        emit DerivativeCreated(id, dtype, msg.sender);
    }

    /// @notice Counterparty joins derivative
    function joinDerivative(uint256 id) external payable nonReentrant {
        DerivativeContract storage derivative = derivatives[id];
        require(derivative.active, "Derivative inactive");
        require(derivative.counterparty == address(0), "Already has counterparty");
        require(msg.value == derivative.premium, "Incorrect premium amount");

        derivative.counterparty = msg.sender;

        emit DerivativeJoined(id, msg.sender);
    }

    /// @notice Settle derivative contract (only owner/oracle)
    function settleDerivative(uint256 id, bool creatorWins) external onlyOwner nonReentrant {
        DerivativeContract storage derivative = derivatives[id];
        require(derivative.active && !derivative.settled, "Already settled or inactive");
        require(block.timestamp >= derivative.expirationTime, "Derivative not yet expired");
        require(derivative.counterparty != address(0), "Counterparty missing");

        derivative.active = false;
        derivative.settled = true;

        uint256 totalPremium = derivative.premium * 2;
        address payable winner = payable(creatorWins ? derivative.creator : derivative.counterparty);

        (bool success,) = winner.call{value: totalPremium}("");
        require(success, "Transfer failed");

        emit DerivativeSettled(id, creatorWins, totalPremium);
    }

    /// @notice Get derivative details
    function getDerivative(uint256 id) external view returns (DerivativeContract memory) {
        return derivatives[id];
    }

    /// @notice Total derivatives created
    function totalDerivatives() external view returns (uint256) {
        return nextDerivativeId;
    }
}
