// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract OptionContract {
    enum OptionType { Call, Put }

    struct Option {
        address holder;
        OptionType optionType;
        uint256 strikePrice; // e.g., in USD (1e18 = $1)
        uint256 currentPrice; // simulated market price
    }

    Option public userOption;

    constructor(
        OptionType _type,
        uint256 _strike,
        uint256 _current
    ) {
        userOption = Option(msg.sender, _type, _strike, _current);
    }

    function isInTheMoney() public view returns (bool) {
        if (userOption.optionType == OptionType.Call) {
            return userOption.currentPrice > userOption.strikePrice;
        } else {
            return userOption.currentPrice < userOption.strikePrice;
        }
    }

    function isOutOfTheMoney() public view returns (bool) {
        return !isInTheMoney();
    }

    function optionDetails() external view returns (address, OptionType, uint256, uint256, bool) {
        return (
            userOption.holder,
            userOption.optionType,
            userOption.strikePrice,
            userOption.currentPrice,
            isInTheMoney()
        );
    }
}
