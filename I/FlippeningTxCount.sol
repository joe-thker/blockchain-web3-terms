// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFeeOracle {
    function dailyFees(address token) external view returns (uint256); // in wei or USD
}

contract FlippeningGasFees {
    address public a;
    address public b;
    IFeeOracle public fee;

    constructor(address _a, address _b, address _f) {
        a = _a;
        b = _b;
        fee = IFeeOracle(_f);
    }

    function isFlipped() external view returns (bool) {
        return fee.dailyFees(a) > fee.dailyFees(b);
    }
}
