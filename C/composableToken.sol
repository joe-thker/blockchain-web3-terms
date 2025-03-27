// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Interface for composable token integration hooks.
/// External modules can implement these functions to react to token events.
interface IComposableTokenHook {
    function onTransfer(address from, address to, uint256 amount) external;
    function onMint(address to, uint256 amount) external;
    function onBurn(address from, uint256 amount) external;
}

/// @notice ComposableToken is an ERC20 token designed with modularity in mind.
/// The owner can register an integration hook contract which will be notified
/// on mint, burn, and transfer events via our public wrapper functions.
contract ComposableToken is ERC20, Ownable {
    /// @notice The integration hook that will receive callbacks on token events.
    IComposableTokenHook public integrationHook;

    /// @notice Emitted when an integration hook is set.
    event IntegrationHookSet(address indexed hookAddress);

    /// @notice Constructor initializes the token with a name and symbol.
    /// The deployer is set as the initial owner.
    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
        Ownable(msg.sender)
    {}

    /// @notice Sets the integration hook contract.
    /// @param hookAddress The address of a contract implementing IComposableTokenHook.
    function setIntegrationHook(address hookAddress) external onlyOwner {
        integrationHook = IComposableTokenHook(hookAddress);
        emit IntegrationHookSet(hookAddress);
    }

    /// @notice Public mint function callable by the owner.
    /// Mints tokens to the specified address and calls the integration hook.
    function mintToken(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        if (address(integrationHook) != address(0)) {
            integrationHook.onMint(to, amount);
        }
    }

    /// @notice Public burn function callable by the owner.
    /// Burns tokens from the specified address and calls the integration hook.
    function burnToken(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
        if (address(integrationHook) != address(0)) {
            integrationHook.onBurn(from, amount);
        }
    }

    /// @notice Overridden transfer function that calls the integration hook after transferring tokens.
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        bool success = super.transfer(recipient, amount);
        if (success && address(integrationHook) != address(0)) {
            integrationHook.onTransfer(_msgSender(), recipient, amount);
        }
        return success;
    }

    /// @notice Overridden transferFrom function that calls the integration hook after transferring tokens.
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        bool success = super.transferFrom(sender, recipient, amount);
        if (success && address(integrationHook) != address(0)) {
            integrationHook.onTransfer(sender, recipient, amount);
        }
        return success;
    }
}
