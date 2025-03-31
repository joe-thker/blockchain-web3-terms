// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DecentralizedCurrency (ERC20)
/// @notice A dynamic, optimized, and secure decentralized currency.
contract DecentralizedCurrency is ERC20Burnable, Ownable, ReentrancyGuard {
    
    uint256 private maxSupply;
    bool public mintingActive;

    // Events
    event TokensMinted(address indexed to, uint256 amount);
    event MintingStatusChanged(bool active);
    event MaxSupplyUpdated(uint256 newMaxSupply);

    /// @notice Constructor initializes token with name, symbol, initial supply, and maximum supply
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint256 _maxSupply
    ) ERC20(name, symbol) Ownable(msg.sender) {
        require(_maxSupply >= initialSupply, "Max supply must be >= initial supply");
        maxSupply = _maxSupply;
        mintingActive = true;
        _mint(msg.sender, initialSupply);
        emit TokensMinted(msg.sender, initialSupply);
    }

    /// @notice Owner can dynamically mint new tokens until max supply is reached.
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(mintingActive, "Minting is not active");
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /// @notice Owner can dynamically pause or activate minting.
    function setMintingActive(bool active) external onlyOwner {
        mintingActive = active;
        emit MintingStatusChanged(active);
    }

    /// @notice Owner can update the max supply dynamically.
    function updateMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply >= totalSupply(), "Cannot set max supply below total supply");
        maxSupply = newMaxSupply;
        emit MaxSupplyUpdated(newMaxSupply);
    }

    /// @notice Retrieve the max supply.
    function getMaxSupply() external view returns (uint256) {
        return maxSupply;
    }
}
