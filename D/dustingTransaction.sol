// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DustTransactionManager
/// @notice A dynamic and optimized ERC20 token that detects "dust" transfers—that is, transfers 
/// with an amount below a specified threshold—by overriding _beforeTokenTransfer. The owner 
/// can also forcibly sweep user balances below the threshold to a designated dustRecipient.
contract DustTransactionManager is ERC20Pausable, Ownable, ReentrancyGuard {
    /// @notice The threshold below which a transfer amount is considered "dust."
    uint256 public dustThreshold;
    /// @notice The address that will receive dust if forcibly swept.
    address public dustRecipient;

    // --- Events ---
    event DustThresholdUpdated(uint256 newThreshold);
    event DustRecipientUpdated(address indexed newRecipient);
    event DustTransferDetected(address indexed from, address indexed to, uint256 amount);
    event DustSwept(address indexed user, uint256 amount);

    /// @notice Constructor sets the token name, symbol, initial supply, dust threshold, and dust recipient.
    /// @param initialSupply The number of tokens (in smallest units) to mint initially to the deployer.
    /// @param _dustThreshold The initial dust threshold.
    /// @param _dustRecipient The address to receive dust if swept.
    constructor(
        uint256 initialSupply,
        uint256 _dustThreshold,
        address _dustRecipient
    ) ERC20("DustCoin", "DUST") Ownable(msg.sender) {
        require(_dustRecipient != address(0), "Invalid dust recipient");
        require(_dustThreshold > 0, "Dust threshold must be > 0");

        _mint(msg.sender, initialSupply);
        dustThreshold = _dustThreshold;
        dustRecipient = _dustRecipient;
    }

    /// @notice Updates the dust threshold. Only the owner can call.
    /// @param newThreshold The new dust threshold.
    function updateDustThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0, "Threshold must be > 0");
        dustThreshold = newThreshold;
        emit DustThresholdUpdated(newThreshold);
    }

    /// @notice Updates the dust recipient address. Only the owner can call.
    /// @param newRecipient The new dust recipient.
    function updateDustRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid address");
        dustRecipient = newRecipient;
        emit DustRecipientUpdated(newRecipient);
    }

    /// @notice Mints tokens to a specified address. Only the owner can call.
    /// @param to The address to receive minted tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Mint amount must be > 0");
        _mint(to, amount);
    }

    /// @notice Burns tokens from a specified address. Only the owner can call.
    /// @param from The address whose tokens will be burned.
    /// @param amount The amount of tokens to burn.
    function burn(address from, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Burn amount must be > 0");
        _burn(from, amount);
    }

    /// @notice Overrides _beforeTokenTransfer to detect dust transfers.
    /// This function is called before any transfer, mint, or burn operation.
    /// If the transfer amount is less than the dust threshold (and it's a standard transfer),
    /// it emits a DustTransferDetected event.
    /// @param from The sender address.
    /// @param to The recipient address.
    /// @param amount The amount being transferred.
    /// @param batchSize The batch size (for ERC1155 compatibility, typically 1 for ERC20).
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount, batchSize);
        // Only check for normal transfers (exclude minting and burning)
        if (from != address(0) && to != address(0) && amount > 0 && amount < dustThreshold) {
            emit DustTransferDetected(from, to, amount);
        }
    }

    /// @notice If a user's entire balance is below the dust threshold, the owner can sweep it to the dustRecipient.
    /// @param user The user whose balance is to be swept.
    function sweepUserDust(address user) external onlyOwner nonReentrant {
        uint256 userBalance = balanceOf(user);
        require(userBalance > 0, "No balance to sweep");
        require(userBalance < dustThreshold, "User balance is not dust");

        _transfer(user, dustRecipient, userBalance);
        emit DustSwept(user, userBalance);
    }
}
