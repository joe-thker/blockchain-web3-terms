// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ExponentialMovingAverage
/// @notice This contract implements an exponential moving average (EMA) calculation using fixed-point arithmetic.
/// The EMA is calculated as:
///   EMA = (alpha * newValue) + ((1 - alpha) * previousEMA)
/// where alpha = 2 / (period + 1) (scaled by 1e18 for precision).
/// The owner can update the period (which recalculates alpha) and update the EMA by providing new data values.
contract ExponentialMovingAverage is Ownable {
    /// @notice The current EMA value, scaled by 1e18.
    uint256 public ema;
    /// @notice The period used for the EMA calculation.
    uint256 public period;
    /// @notice The smoothing factor alpha, scaled by 1e18.
    uint256 public alpha;
    /// @notice Whether the EMA has been initialized.
    bool public initialized;

    /// @notice Emitted when the EMA is updated.
    /// @param newEMA The new EMA value (scaled by 1e18).
    /// @param newValue The new data point provided (assumed to be scaled by 1e18).
    event EMAUpdated(uint256 newEMA, uint256 newValue);

    /// @notice Emitted when the period is updated.
    /// @param newPeriod The new period value.
    /// @param newAlpha The new alpha value (scaled by 1e18).
    event PeriodUpdated(uint256 newPeriod, uint256 newAlpha);

    /**
     * @notice Constructor sets the initial period and calculates alpha.
     * @param _period The initial period for EMA calculation.
     */
    constructor(uint256 _period) Ownable(msg.sender) {
        require(_period > 0, "Period must be > 0");
        period = _period;
        // alpha = 2 / (period + 1), scaled by 1e18.
        alpha = (2 * 1e18) / (period + 1);
    }

    /**
     * @notice Updates the EMA with a new data point.
     * If not initialized, the EMA is set to the new value.
     * Otherwise, the EMA is updated using the formula:
     *   EMA = (alpha * newValue) + ((1e18 - alpha) * previousEMA) / 1e18
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
     * @notice Updates the period used for EMA calculation.
     * This also recalculates the alpha smoothing factor.
     * @param newPeriod The new period value (must be > 0).
     */
    function updatePeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod > 0, "Period must be > 0");
        period = newPeriod;
        alpha = (2 * 1e18) / (period + 1);
        emit PeriodUpdated(newPeriod, alpha);
    }
}
