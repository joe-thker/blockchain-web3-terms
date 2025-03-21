// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the ABDKMath64x64 library (ensure this file is available in your project)
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract BondingCurves {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    // Parameters in 64x64 fixed point format:
    // initialPrice (P0), slope (m) for linear and logarithmic curves, and growthFactor for exponential curve.
    int128 public initialPrice;   // e.g., ABDKMath64x64.fromUInt(100) for 100 units
    int128 public slope;          // e.g., ABDKMath64x64.fromUInt(1) for 1 unit increase per token
    int128 public growthFactor;   // e.g., to represent 1.05, use ABDKMath64x64.div(ABDKMath64x64.fromUInt(105), ABDKMath64x64.fromUInt(100))
    
    // Total tokens minted (supply)
    uint256 public totalSupply;

    // Event emitted when a token is bought.
    event TokenBought(address indexed buyer, uint256 newTotalSupply);

    /// @notice Constructor to set the bonding curve parameters.
    /// @param _initialPrice The initial price (64x64 fixed point).
    /// @param _slope The slope for linear and logarithmic curves (64x64 fixed point).
    /// @param _growthFactor The growth factor for the exponential curve (64x64 fixed point).
    constructor(int128 _initialPrice, int128 _slope, int128 _growthFactor) {
        initialPrice = _initialPrice;
        slope = _slope;
        growthFactor = _growthFactor;
        totalSupply = 0;
    }

    /// @notice Returns the price using a linear bonding curve.
    /// @param supply The token supply.
    /// @return price The computed token price (64x64 fixed point).
    function getLinearPrice(uint256 supply) public view returns (int128 price) {
        // Price = initialPrice + slope * supply
        price = initialPrice.add(slope.mul(ABDKMath64x64.fromUInt(supply)));
    }

    /// @notice Returns the price using an exponential bonding curve.
    /// @param supply The token supply.
    /// @return price The computed token price (64x64 fixed point).
    function getExponentialPrice(uint256 supply) public view returns (int128 price) {
        // Price = initialPrice * (growthFactor ^ supply)
        // Compute growthFactor^supply as exp(ln(growthFactor) * supply)
        int128 exponent = ABDKMath64x64.ln(growthFactor).mul(ABDKMath64x64.fromUInt(supply));
        int128 factor = ABDKMath64x64.exp(exponent);
        price = initialPrice.mul(factor);
    }

    /// @notice Returns the price using a logarithmic bonding curve.
    /// @param supply The token supply.
    /// @return price The computed token price (64x64 fixed point).
    function getLogarithmicPrice(uint256 supply) public view returns (int128 price) {
        // Price = initialPrice + slope * ln(supply + 1)
        int128 lnValue = ABDKMath64x64.ln(ABDKMath64x64.fromUInt(supply + 1));
        price = initialPrice.add(slope.mul(lnValue));
    }

    /// @notice Simulates purchasing one token by incrementing the total supply.
    function buyToken() public {
        totalSupply += 1;
        emit TokenBought(msg.sender, totalSupply);
    }

    /// @notice Returns the current token price based on the linear bonding curve.
    function currentLinearPrice() public view returns (int128) {
        return getLinearPrice(totalSupply);
    }

    /// @notice Returns the current token price based on the exponential bonding curve.
    function currentExponentialPrice() public view returns (int128) {
        return getExponentialPrice(totalSupply);
    }

    /// @notice Returns the current token price based on the logarithmic bonding curve.
    function currentLogarithmicPrice() public view returns (int128) {
        return getLogarithmicPrice(totalSupply);
    }
}
