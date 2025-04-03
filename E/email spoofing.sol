// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ExponentialMovingAverage
/// @notice This contract calculates an exponential moving average (EMA) using fixed‑point arithmetic.
/// The EMA is updated using the formula:
///   EMA = (alpha * newValue) + ((1e18 - alpha) * previousEMA) / 1e18,
/// where alpha = 2e18 / (period + 1).
/// The owner can update the EMA with new data and adjust the period (and thus alpha).
contract ExponentialMovingAverage is Ownable {
    /// @notice The current EMA value, scaled by 1e18.
    uint256 public ema;
    /// @notice The period used for the EMA calculation.
    uint256 public period;
    /// @notice The smoothing factor alpha, scaled by 1e18.
    uint256 public alpha;
    /// @notice A flag indicating whether the EMA has been initialized.
    bool public initialized;

    /// @notice Emitted when the EMA is updated.
    /// @param newEMA The new EMA value (scaled by 1e18).
    /// @param newValue The new data point provided (scaled by 1e18).
    event EMAUpdated(uint256 newEMA, uint256 newValue);

    /// @notice Emitted when the period is updated.
    /// @param newPeriod The new period value.
    /// @param newAlpha The new alpha value (scaled by 1e18).
    event PeriodUpdated(uint256 newPeriod, uint256 newAlpha);

    /**
     * @notice Constructor sets the initial period and calculates the initial alpha.
     * @param _period The initial period for the EMA calculation.
     */
    constructor(uint256 _period) Ownable(msg.sender) {
        require(_period > 0, "Period must be > 0");
        period = _period;
        // Calculate alpha: 2e18 / (period + 1)
        alpha = (2 * 1e18) / (period + 1);
    }

    /**
     * @notice Updates the EMA with a new data point.
     * If the EMA has not been initialized, it is set to the new value.
     * Otherwise, it updates according to the formula:
     *   EMA = (alpha * newValue + (1e18 - alpha) * previousEMA) / 1e18.
     * @param newValue The new data point to incorporate (scaled by 1e18).
     */
    function updateEMA(uint256 newValue) external onlyOwner {
        require(newValue > 0, "New value must be > 0");
        if (!initialized) {
            ema = newValue;
            initialized = true;
        } else {
            ema = (alpha * newValue + (1e18 - alpha) * ema) / 1e18;
        }
        emit EMAUpdated(ema, newValue);
    }

    /**
     * @notice Returns the current EMA value.
     * @return The current EMA value (scaled by 1e18).
     */
    function getEMA() external view returns (uint256) {
        return ema;
    }

    /**
     * @notice Updates the period used for the EMA calculation and recalculates alpha.
     * @param newPeriod The new period value (must be > 0).
     */
    function updatePeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod > 0, "Period must be > 0");
        period = newPeriod;
        alpha = (2 * 1e18) / (period + 1);
        emit PeriodUpdated(newPeriod, alpha);
    }
}
