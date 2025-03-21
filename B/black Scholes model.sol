// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract BlackScholesModel {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    // Dummy cumulative normal distribution function.
    // For demonstration, this is a crude linear approximation: N(x) ≈ 0.5 + 0.3 * x.
    // In practice, a more accurate approximation is required.
    function cumulativeNormalDistribution(int128 x) internal pure returns (int128) {
        int128 half = ABDKMath64x64.div(ABDKMath64x64.fromUInt(1), ABDKMath64x64.fromUInt(2)); // 0.5
        int128 slope = ABDKMath64x64.div(ABDKMath64x64.fromUInt(3), ABDKMath64x64.fromUInt(10)); // 0.3
        return half.add(slope.mul(x));
    }

    /// @notice Computes the Black-Scholes call option price.
    /// @param S Underlying asset price (as a 64x64 fixed point number)
    /// @param K Strike price (as a 64x64 fixed point number)
    /// @param T Time to expiration in years (as a 64x64 fixed point number)
    /// @param r Risk-free rate (as a 64x64 fixed point number)
    /// @param sigma Volatility (as a 64x64 fixed point number)
    /// @return callPrice The call option price (as a 64x64 fixed point number)
    function blackScholesCallPrice(
        int128 S,
        int128 K,
        int128 T,
        int128 r,
        int128 sigma
    ) public pure returns (int128 callPrice) {
        // Calculate sqrt(T) once
        int128 sqrtT = ABDKMath64x64.sqrt(T);
        
        // Calculate d1 using inlined operations
        int128 d1 = (
            ABDKMath64x64.ln(S.div(K)) + 
            (r.add(sigma.mul(sigma).div(2)).mul(T))
        ).div(sigma.mul(sqrtT));
        
        // Calculate d2
        int128 d2 = d1 - sigma.mul(sqrtT);
        
        // Calculate dummy cumulative normal distribution values for d1 and d2
        int128 Nd1 = cumulativeNormalDistribution(d1);
        int128 Nd2 = cumulativeNormalDistribution(d2);
        
        // Calculate discount factor: exp(-r * T)
        int128 discount = ABDKMath64x64.exp(r.neg().mul(T));
        
        // Black-Scholes call price: C = S * N(d1) - K * exp(-r * T) * N(d2)
        callPrice = S.mul(Nd1) - K.mul(discount).mul(Nd2);
    }
}
