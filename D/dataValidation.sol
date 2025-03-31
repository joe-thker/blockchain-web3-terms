// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DataValidation
/// @notice This contract validates numeric data against parameters set by the owner.
/// The owner can update the minimum and maximum acceptable values.
/// Users submit data and the contract records whether the data is valid based on these parameters.
contract DataValidation is Ownable, ReentrancyGuard {
    // Minimum and maximum acceptable values.
    uint256 public minValue;
    uint256 public maxValue;

    // Mapping to store the last submitted data for each user.
    mapping(address => uint256) public lastSubmittedData;
    // Mapping to store whether the last submitted data is valid.
    mapping(address => bool) public isDataValid;

    // --- Events ---
    event ValidationParametersUpdated(uint256 newMin, uint256 newMax);
    event DataSubmitted(address indexed user, uint256 data, bool valid);

    /// @notice Constructor sets initial validation parameters.
    /// @param _minValue The minimum acceptable value.
    /// @param _maxValue The maximum acceptable value.
    constructor(uint256 _minValue, uint256 _maxValue) Ownable(msg.sender) {
        require(_minValue <= _maxValue, "minValue must be <= maxValue");
        minValue = _minValue;
        maxValue = _maxValue;
        emit ValidationParametersUpdated(_minValue, _maxValue);
    }

    /// @notice Allows the owner to update the validation parameters.
    /// @param _minValue The new minimum acceptable value.
    /// @param _maxValue The new maximum acceptable value.
    function updateValidationParameters(uint256 _minValue, uint256 _maxValue) external onlyOwner {
        require(_minValue <= _maxValue, "minValue must be <= maxValue");
        minValue = _minValue;
        maxValue = _maxValue;
        emit ValidationParametersUpdated(_minValue, _maxValue);
    }

    /// @notice Allows a user to submit data which is validated against the current parameters.
    /// @param data The numeric data submitted by the user.
    /// @return valid A boolean indicating if the data is valid.
    function submitData(uint256 data) external nonReentrant returns (bool valid) {
        valid = (data >= minValue && data <= maxValue);
        lastSubmittedData[msg.sender] = data;
        isDataValid[msg.sender] = valid;
        emit DataSubmitted(msg.sender, data, valid);
        return valid;
    }
}
