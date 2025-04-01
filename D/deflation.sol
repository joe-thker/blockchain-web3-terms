// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DeflationaryToken
/// @notice An ERC20 token with a deflationary mechanism that burns a percentage of tokens on every transfer.
/// The burn fee is dynamic and can be updated by the owner. The token supply can also be managed via minting and burning.
contract DeflationaryToken is ERC20, Ownable, ReentrancyGuard {
    // Burn fee in basis points (1 basis point = 0.01%). For example, 200 means 2%
    uint256 public burnFee;
    // Maximum token supply (in smallest units)
    uint256 public maxSupply;

    // Events
    event BurnFeeUpdated(uint256 newBurnFee);
    event MaxSupplyUpdated(uint256 newMaxSupply);

    /// @notice Constructor initializes the token.
    /// @param name_ The token name.
    /// @param symbol_ The token symbol.
    /// @param initialSupply The initial supply minted to the deployer.
    /// @param _maxSupply The maximum token supply.
    /// @param initialBurnFee The initial burn fee in basis points.
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        uint256 _maxSupply,
        uint256 initialBurnFee
    )
        ERC20(name_, symbol_)
        Ownable(msg.sender)
    {
        require(_maxSupply >= initialSupply, "Max supply must be >= initial supply");
        require(initialBurnFee <= 1000, "Burn fee too high"); // Maximum 10%
        maxSupply = _maxSupply;
        burnFee = initialBurnFee;
        _mint(msg.sender, initialSupply);
    }

    /// @notice Updates the burn fee (in basis points). Only the owner can update.
    /// @param newBurnFee The new burn fee in basis points.
    function setBurnFee(uint256 newBurnFee) external onlyOwner {
        require(newBurnFee <= 1000, "Burn fee too high");
        burnFee = newBurnFee;
        emit BurnFeeUpdated(newBurnFee);
    }

    /// @notice Updates the maximum token supply. Only the owner can update.
    /// @param newMaxSupply The new maximum supply.
    function updateMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply >= totalSupply(), "New max supply less than total supply");
        maxSupply = newMaxSupply;
        emit MaxSupplyUpdated(newMaxSupply);
    }

    /// @notice Overrides the ERC20 transfer function to apply a burn fee.
    /// @param recipient The address to receive tokens.
    /// @param amount The total amount to transfer (in token units).
    /// @return success Boolean indicating success.
    function transfer(address recipient, uint256 amount) public virtual override returns (bool success) {
        require(recipient != address(0), "ERC20: transfer to zero address");

        uint256 fee = (amount * burnFee) / 10000;
        uint256 amountAfterFee = amount - fee;

        // Call parent's transfer with the net amount.
        success = super.transfer(recipient, amountAfterFee);
        // Burn the fee amount from the sender.
        if (fee > 0) {
            _burn(_msgSender(), fee);
        }
    }

    /// @notice Overrides the ERC20 transferFrom function to apply a burn fee.
    /// @param sender The address sending tokens.
    /// @param recipient The address receiving tokens.
    /// @param amount The total amount to transfer (in token units).
    /// @return success Boolean indicating success.
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool success) {
        require(recipient != address(0), "ERC20: transfer to zero address");

        uint256 fee = (amount * burnFee) / 10000;
        uint256 amountAfterFee = amount - fee;

        // Call parent's transferFrom with the net amount.
        success = super.transferFrom(sender, recipient, amountAfterFee);
        // Burn the fee amount from the sender.
        if (fee > 0) {
            _burn(sender, fee);
        }
    }

    /// @notice Mints new tokens to a specified address. Only the owner can mint.
    /// @param to The recipient address.
    /// @param amount The amount to mint.
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
    }

    /// @notice Burns tokens from a specified address. Only the owner can burn.
    /// @param from The address from which tokens will be burned.
    /// @param amount The amount to burn.
    function burn(address from, uint256 amount) external onlyOwner nonReentrant {
        _burn(from, amount);
    }
}
