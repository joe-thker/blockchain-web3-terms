// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SimpleBeaconChain
/// @notice A simplified simulation of a Beacon Chain that tracks registered validators.
contract SimpleBeaconChain {
    address[] public validators;

    event ValidatorRegistered(address validator);

    /// @notice Allows a validator to register.
    function registerValidator() public {
        validators.push(msg.sender);
        emit ValidatorRegistered(msg.sender);
    }

    /// @notice Returns the total number of registered validators.
    /// @return The number of validators.
    function getValidatorCount() public view returns (uint256) {
        return validators.length;
    }
}
