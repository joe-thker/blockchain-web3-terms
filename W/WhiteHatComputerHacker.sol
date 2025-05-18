// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title WhiteHatRescue - Securely rescues funds from vulnerable contracts and returns them
contract WhiteHatRescue {
    address public immutable whitehat;
    address public immutable target;
    address public immutable safeReceiver;

    event RescueSuccess(address indexed whitehat, uint256 rescuedAmount);
    event RescueFailed(address indexed target);

    constructor(address _target, address _safeReceiver) {
        whitehat = msg.sender;
        target = _target;
        safeReceiver = _safeReceiver;
    }

    /// @notice White hat initiates rescue call
    function rescue() external {
        require(msg.sender == whitehat, "Not authorized");

        // Call vulnerable contract's withdraw() or transfer() method
        (bool ok, ) = target.call(abi.encodeWithSignature("withdraw()"));
        require(ok, "Withdraw failed");

        uint256 balance = address(this).balance;
        (bool sent, ) = safeReceiver.call{value: balance}("");
        require(sent, "Send failed");

        emit RescueSuccess(msg.sender, balance);
    }

    receive() external payable {}
}
