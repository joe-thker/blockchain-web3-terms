// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BitcoinMiseryIndex
/// @notice A simplified contract to simulate a Bitcoin Misery Index by combining volatility and fear metrics.
/// @dev Both metrics are expected to be provided scaled by 1e18.
contract BitcoinMiseryIndex {
    address public owner;
    
    // Metrics scaled by 1e18 for fixed-point precision.
    uint256 public volatility;  // Represents market volatility
    uint256 public fearFactor;  // Represents market fear or sentiment
    
    // Event emitted when the metrics and misery index are updated.
    event MetricsUpdated(uint256 volatility, uint256 fearFactor, uint256 miseryIndex);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /// @notice Constructor sets the deployer as the owner.
    constructor() {
        owner = msg.sender;
    }
    
    /// @notice Updates the volatility and fear metrics.
    /// @param _volatility The updated volatility metric (scaled by 1e18).
    /// @param _fearFactor The updated fear factor metric (scaled by 1e18).
    function updateMetrics(uint256 _volatility, uint256 _fearFactor) external onlyOwner {
        volatility = _volatility;
        fearFactor = _fearFactor;
        uint256 miseryIndex = getMiseryIndex();
        emit MetricsUpdated(_volatility, _fearFactor, miseryIndex);
    }
    
    /// @notice Returns the current Bitcoin Misery Index.
    /// @return The misery index, calculated as volatility + fearFactor.
    function getMiseryIndex() public view returns (uint256) {
        return volatility + fearFactor;
    }
}
