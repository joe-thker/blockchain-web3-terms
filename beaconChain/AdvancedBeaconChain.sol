// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title AdvancedBeaconChain
/// @notice A simplified simulation of a Beacon Chain that tracks validators with deposits and epochs.
contract AdvancedBeaconChain {
    uint256 public constant EPOCH_DURATION = 100; // For simulation, one epoch = 100 blocks
    uint256 public currentEpoch;

    struct Validator {
        address validator;
        uint256 deposit;
    }

    Validator[] public validators;

    event ValidatorRegistered(address validator, uint256 deposit);
    event EpochAdvanced(uint256 newEpoch);

    /// @notice Constructor initializes the current epoch based on the current block number.
    constructor() {
        currentEpoch = block.number / EPOCH_DURATION;
    }

    /// @notice Allows a validator to register with a deposit.
    /// @dev The deposit is sent as part of the transaction.
    function registerValidator() public payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        validators.push(Validator({validator: msg.sender, deposit: msg.value}));
        emit ValidatorRegistered(msg.sender, msg.value);
    }

    /// @notice Advances the epoch based on the current block number.
    function advanceEpoch() public {
        uint256 newEpoch = block.number / EPOCH_DURATION;
        require(newEpoch > currentEpoch, "Epoch has not advanced yet");
        currentEpoch = newEpoch;
        emit EpochAdvanced(newEpoch);
    }

    /// @notice Returns the total number of registered validators.
    /// @return The number of validators.
    function getValidatorCount() public view returns (uint256) {
        return validators.length;
    }
}
