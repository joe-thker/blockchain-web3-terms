// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DecentralizedStableCoin
/// @notice A dynamic, optimized, and secure ERC20 stable coin contract.
/// Minting and burning are restricted to the owner or authorized minters.
/// The owner can also update the maximum supply dynamically.
contract DecentralizedStableCoin is ERC20, Ownable, ReentrancyGuard {
    // Mapping to track addresses authorized to mint and burn tokens.
    mapping(address => bool) public authorizedMinters;

    // Maximum supply of tokens.
    uint256 public maxSupply;

    // Events
    event MinterAuthorized(address indexed account);
    event MinterRevoked(address indexed account);
    event MaxSupplyUpdated(uint256 newMaxSupply);

    /// @notice Constructor initializes the stable coin with a name, symbol, initial supply, and maximum supply.
    /// @param name_ The name of the token.
    /// @param symbol_ The symbol of the token.
    /// @param initialSupply The initial token supply (in smallest units).
    /// @param _maxSupply The maximum token supply (must be at least initialSupply).
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        uint256 _maxSupply
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        require(_maxSupply >= initialSupply, "Max supply must be >= initial supply");
        maxSupply = _maxSupply;
        _mint(msg.sender, initialSupply);
    }

    /// @notice Authorizes an account to mint and burn tokens.
    /// @param account The address to authorize.
    function authorizeMinter(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        authorizedMinters[account] = true;
        emit MinterAuthorized(account);
    }

    /// @notice Revokes minting/burning authorization for an account.
    /// @param account The address to revoke.
    function revokeMinter(address account) external onlyOwner {
        require(authorizedMinters[account], "Address not authorized");
        authorizedMinters[account] = false;
        emit MinterRevoked(account);
    }

    /// @notice Mints new stable coins to a specified address.
    /// Only the owner or an authorized minter can mint tokens.
    /// @param to The recipient address.
    /// @param amount The token amount to mint (in smallest units).
    function mint(address to, uint256 amount) external nonReentrant {
        require(authorizedMinters[msg.sender] || msg.sender == owner(), "Not authorized to mint");
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
    }

    /// @notice Burns stable coins from a specified address.
    /// Only the owner or an authorized minter can burn tokens.
    /// @param from The address from which tokens will be burned.
    /// @param amount The token amount to burn (in smallest units).
    function burn(address from, uint256 amount) external nonReentrant {
        require(authorizedMinters[msg.sender] || msg.sender == owner(), "Not authorized to burn");
        _burn(from, amount);
    }

    /// @notice Updates the maximum supply of tokens.
    /// @param newMaxSupply The new maximum supply (must be >= current total supply).
    function updateMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply >= totalSupply(), "New max supply less than total supply");
        maxSupply = newMaxSupply;
        emit MaxSupplyUpdated(newMaxSupply);
    }
}
