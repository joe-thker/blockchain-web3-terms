// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GraySwanGuard {
    address public admin;
    uint256 public lastPrice;
    bool public paused;

    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    event ProtocolPaused(string reason);
    event ProtocolResumed();

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier notPaused() {
        require(!paused, "Protocol paused due to risk");
        _;
    }

    constructor(uint256 initialPrice) {
        admin = msg.sender;
        lastPrice = initialPrice;
    }

    /// @notice Admin updates price (simulating oracle)
    function updatePrice(uint256 newPrice) external onlyAdmin {
        emit PriceUpdated(lastPrice, newPrice);

        // Gray swan trigger: price drops >50%
        if (newPrice < (lastPrice / 2)) {
            paused = true;
            emit ProtocolPaused("Gray Swan Triggered: >50% drop");
        }

        lastPrice = newPrice;
    }

    /// @notice Resume protocol manually
    function resumeProtocol() external onlyAdmin {
        require(paused, "Not paused");
        paused = false;
        emit ProtocolResumed();
    }

    /// @notice Example function that gets blocked when paused
    function sensitiveAction() external notPaused {
        // Perform core logic
    }
}
