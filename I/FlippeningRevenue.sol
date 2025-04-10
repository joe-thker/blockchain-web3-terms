// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRevenueOracle {
    function revenue(address protocol) external view returns (uint256);
}

contract FlippeningRevenue {
    address public a;
    address public b;
    IRevenueOracle public rev;

    constructor(address _a, address _b, address _rev) {
        a = _a;
        b = _b;
        rev = IRevenueOracle(_rev);
    }

    function flipped() external view returns (bool) {
        return rev.revenue(a) > rev.revenue(b);
    }
}
