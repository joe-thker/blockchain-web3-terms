// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ERC884Token
/// @notice An ERC20-based token representing shares (ERC‑884 standard) with a mandatory shareholder registry.
/// Only registered shareholders may receive tokens (except during minting or burning).
contract ERC884Token is ERC20Pausable, Ownable {
    // Mapping to track registered shareholders.
    mapping(address => bool) private _isShareholder;
    // Array to store shareholder addresses.
    address[] private _shareholders;

    // --- Events ---
    event ShareholderRegistered(address indexed shareholder);
    event ShareholderDeregistered(address indexed shareholder);

    /**
     * @notice Constructor initializes the token with a name, symbol, and initial supply minted to the owner.
     * The deployer is automatically registered as a shareholder.
     * @param name_ The token name.
     * @param symbol_ The token symbol.
     * @param initialSupply The initial supply (in smallest units) minted to the owner.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        require(initialSupply > 0, "Initial supply must be > 0");
        _mint(msg.sender, initialSupply);
        _registerShareholder(msg.sender);
    }

    /**
     * @notice Registers an address as a shareholder.
     * @param shareholder The address to register.
     */
    function registerShareholder(address shareholder) external onlyOwner {
        _registerShareholder(shareholder);
    }

    /**
     * @dev Internal function to register a shareholder.
     * @param shareholder The address to register.
     */
    function _registerShareholder(address shareholder) internal {
        require(shareholder != address(0), "Invalid shareholder address");
        require(!_isShareholder[shareholder], "Already registered");
        _isShareholder[shareholder] = true;
        _shareholders.push(shareholder);
        emit ShareholderRegistered(shareholder);
    }

    /**
     * @notice Deregisters a shareholder.
     * @param shareholder The address to deregister.
     */
    function deregisterShareholder(address shareholder) external onlyOwner {
        require(_isShareholder[shareholder], "Not a registered shareholder");
        _isShareholder[shareholder] = false;
        // Remove shareholder from the array (order not preserved)
        uint256 len = _shareholders.length;
        for (uint256 i = 0; i < len; i++) {
            if (_shareholders[i] == shareholder) {
                _shareholders[i] = _shareholders[len - 1];
                _shareholders.pop();
                break;
            }
        }
        emit ShareholderDeregistered(shareholder);
    }

    /**
     * @notice Checks whether an address is a registered shareholder.
     * @param account The address to check.
     * @return True if the address is registered; otherwise, false.
     */
    function isShareholder(address account) external view returns (bool) {
        return _isShareholder[account];
    }

    /**
     * @notice Returns the list of registered shareholders.
     * @return An array of shareholder addresses.
     */
    function getShareholders() external view returns (address[] memory) {
        return _shareholders;
    }

    /**
     * @notice Overrides _beforeTokenTransfer to enforce that for regular transfers (i.e. not minting or burning)
     * both the sender and the recipient must be registered shareholders.
     * @param from The address sending tokens (zero when minting).
     * @param to The address receiving tokens (zero when burning).
     * @param amount The number of tokens to transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // For minting or burning, from or to is the zero address.
        if (from != address(0) && to != address(0)) {
            require(_isShareholder[from], "Sender is not a registered shareholder");
            require(_isShareholder[to], "Recipient is not a registered shareholder");
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}
