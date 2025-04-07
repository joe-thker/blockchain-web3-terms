// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title SecureUpgradeableToken
/// @notice UUPS upgradeable token with protected mint and upgrade logic
contract SecureUpgradeableToken is ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    /// @notice Initializer replaces constructor in upgradeable contracts
    function initialize() external initializer {
        __ERC20_init("UpSafe", "UPS");
        __Ownable_init(msg.sender); // ✅ Explicitly set initial owner
    }

    /// @notice Only the owner can authorize an upgrade
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @notice Only the owner can mint new tokens
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
