// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title UtilityToken
/// @notice An ERC20 token named “Utility.” The owner (which will be the DualTokenEconomy contract) can mint and burn.
contract UtilityToken is ERC20, Ownable, ReentrancyGuard {
    /// @notice Constructor sets token name/symbol and mints an initial supply to the owner if desired.
    /// We pass the owner in the constructor from the aggregator, or you can pass msg.sender if deployed stand-alone.
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {}

    /// @notice Mints new tokens to a recipient, only callable by the owner.
    /// @param to The address to receive minted tokens.
    /// @param amount The amount to mint (in smallest units).
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Mint amount must be > 0");
        _mint(to, amount);
    }

    /// @notice Burns tokens from a specified address, only callable by the owner.
    /// @param from The address from which tokens are burned.
    /// @param amount The amount to burn.
    function burn(address from, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Burn amount must be > 0");
        _burn(from, amount);
    }
}

/// @title GovernanceToken
/// @notice An ERC20 token named “Governance.” The owner (which will be the DualTokenEconomy contract) can mint and burn.
contract GovernanceToken is ERC20, Ownable, ReentrancyGuard {
    /// @notice Constructor sets token name/symbol, optionally mints initial supply to the owner.
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {}

    /// @notice Mints new tokens to a recipient, only callable by the owner.
    /// @param to The address to receive minted tokens.
    /// @param amount The amount to mint (in smallest units).
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Mint amount must be > 0");
        _mint(to, amount);
    }

    /// @notice Burns tokens from a specified address, only callable by the owner.
    /// @param from The address from which tokens are burned.
    /// @param amount The amount to burn.
    function burn(address from, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Burn amount must be > 0");
        _burn(from, amount);
    }
}

/// @title DualTokenEconomy
/// @notice This aggregator contract deploys (or references) two ERC20 tokens: a UtilityToken and a GovernanceToken.
/// It can mint/burn them, and provides a simplistic “swap” from Utility to Governance at a fixed ratio, 
/// illustrating a basic dual token system.
contract DualTokenEconomy is Ownable, ReentrancyGuard {
    UtilityToken public utility;
    GovernanceToken public governance;

    // A simple fixed ratio for demonstration, e.g. 1 governance = 100 utility
    // Adjust as needed or implement a more complex formula.
    uint256 public swapRatio;

    /// @notice Constructor deploys the two tokens (Utility and Governance),
    /// sets this contract as their owner, and sets an initial swap ratio.
    /// @param initialSwapRatio The ratio for Utility -> Governance conversion. e.g. 100 => 1 GOV = 100 Utility.
    constructor(uint256 initialSwapRatio) Ownable(msg.sender) {
        require(initialSwapRatio > 0, "Swap ratio must be > 0");

        // Deploy UtilityToken
        utility = new UtilityToken("Utility", "UTL");
        // Transfer ownership of UtilityToken to this aggregator contract itself
        // so this aggregator can mint/burn. Alternatively, you could keep aggregator as msg.sender.
        utility.transferOwnership(address(this));

        // Deploy GovernanceToken
        governance = new GovernanceToken("Governance", "GOV");
        governance.transferOwnership(address(this));

        swapRatio = initialSwapRatio;
    }

    /// @notice Updates the swap ratio (if needed). Only aggregator owner can do this.
    /// @param newRatio The new ratio for Utility -> Governance.
    function updateSwapRatio(uint256 newRatio) external onlyOwner {
        require(newRatio > 0, "Swap ratio must be > 0");
        swapRatio = newRatio;
    }

    // ------------------------------------------------------------------------
    // Mint/Burn Functions
    // ------------------------------------------------------------------------
    // The aggregator can mint and burn both tokens. Real usage might restrict to certain logic.

    /// @notice Mints utility tokens to a specified address.
    /// @param to The address receiving minted utility tokens.
    /// @param amount The amount to mint.
    function mintUtility(address to, uint256 amount) external onlyOwner nonReentrant {
        utility.mint(to, amount);
    }

    /// @notice Burns utility tokens from a specified address.
    /// @param from The address from which tokens are burned.
    /// @param amount The amount to burn.
    function burnUtility(address from, uint256 amount) external onlyOwner nonReentrant {
        utility.burn(from, amount);
    }

    /// @notice Mints governance tokens to a specified address.
    /// @param to The address receiving minted governance tokens.
    /// @param amount The amount to mint.
    function mintGovernance(address to, uint256 amount) external onlyOwner nonReentrant {
        governance.mint(to, amount);
    }

    /// @notice Burns governance tokens from a specified address.
    /// @param from The address from which tokens are burned.
    /// @param amount The amount to burn.
    function burnGovernance(address from, uint256 amount) external onlyOwner nonReentrant {
        governance.burn(from, amount);
    }

    // ------------------------------------------------------------------------
    // Swap Logic
    // ------------------------------------------------------------------------
    // A simple demonstration: user “swaps” some amount of Utility for Governance at the set ratio.
    // e.g. if ratio=100 => user must deposit 100 Utility to receive 1 Governance.

    /// @notice Users call this to swap utility tokens for governance tokens, at the current swap ratio.
    /// Must have approved this aggregator for `utilityAmount` of utility tokens.
    /// @param utilityAmount The quantity of Utility tokens to swap.
    function swapUtilityForGovernance(uint256 utilityAmount) external nonReentrant {
        require(utilityAmount > 0, "Must swap > 0");
        // 1 Governance = swapRatio Utility => governanceMint = utilityAmount / swapRatio
        uint256 governanceOut = utilityAmount / swapRatio;
        require(governanceOut > 0, "Utility amount too small for 1 unit of governance");

        // Transfer user’s Utility from them to aggregator
        bool success = utility.transferFrom(msg.sender, address(this), utilityAmount);
        require(success, "Utility transfer failed");

        // aggregator might store or burn these utility tokens. 
        // We'll burn them to remove them from circulation, typical approach in a swap scenario.
        utility.burn(address(this), utilityAmount);

        // aggregator mints governance tokens to user
        governance.mint(msg.sender, governanceOut);
    }

    // ------------------------------------------------------------------------
    // Additional demonstration or logic can be added. This is minimal for a “dual token” approach.
    // ------------------------------------------------------------------------
}
