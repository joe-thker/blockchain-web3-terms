// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title EmissionToken
/// @notice An ERC20 token with a dynamic emission schedule. Tokens are minted continuously
/// based on an emission rate (tokens per second, scaled by 1e18) and sent to a treasury address.
/// Anyone can trigger emission via mintEmission(); the owner can update the emission rate and treasury.
contract EmissionToken is ERC20, Ownable, ReentrancyGuard {
    /// @notice Emission rate in tokens per second (scaled by 1e18 for precision).
    uint256 public emissionRate;
    /// @notice Timestamp of the last emission update.
    uint256 public lastEmissionTime;
    /// @notice The treasury address to which emitted tokens are minted.
    address public treasury;

    /// @notice Emitted when new tokens are minted via emission.
    /// @param amount The amount of tokens minted.
    /// @param timestamp The time when tokens were minted.
    event EmissionMinted(uint256 amount, uint256 timestamp);
    /// @notice Emitted when the emission rate is updated.
    /// @param newEmissionRate The new emission rate.
    event EmissionRateUpdated(uint256 newEmissionRate);
    /// @notice Emitted when the treasury address is updated.
    /// @param newTreasury The new treasury address.
    event TreasuryUpdated(address newTreasury);

    /**
     * @notice Constructor sets the token parameters, initial emission rate, and treasury.
     * @param initialSupply The initial token supply minted to the deployer.
     * @param initialEmissionRate The initial emission rate (tokens per second, scaled by 1e18).
     * @param _treasury The treasury address that will receive emitted tokens.
     */
    constructor(
        uint256 initialSupply,
        uint256 initialEmissionRate,
        address _treasury
    ) ERC20("EmissionToken", "EMT") Ownable(msg.sender) {
        require(_treasury != address(0), "Invalid treasury address");
        require(initialEmissionRate > 0, "Emission rate must be > 0");

        _mint(msg.sender, initialSupply);
        emissionRate = initialEmissionRate;
        treasury = _treasury;
        lastEmissionTime = block.timestamp;
    }

    /**
     * @notice Triggers the emission of new tokens based on time elapsed.
     * Anyone can call this function. It calculates:
     *   tokensToMint = emissionRate * (currentTime - lastEmissionTime) / 1e18.
     * Emitted tokens are minted to the treasury address.
     */
    function mintEmission() external nonReentrant {
        uint256 currentTime = block.timestamp;
        require(currentTime > lastEmissionTime, "No time elapsed");

        uint256 elapsed = currentTime - lastEmissionTime;
        uint256 tokensToMint = (emissionRate * elapsed) / 1e18;
        require(tokensToMint > 0, "No tokens to mint");

        lastEmissionTime = currentTime;
        _mint(treasury, tokensToMint);
        emit EmissionMinted(tokensToMint, currentTime);
    }

    /**
     * @notice Allows the owner to update the emission rate.
     * @param newEmissionRate The new emission rate (tokens per second, scaled by 1e18).
     */
    function updateEmissionRate(uint256 newEmissionRate) external onlyOwner {
        require(newEmissionRate > 0, "Emission rate must be > 0");
        emissionRate = newEmissionRate;
        emit EmissionRateUpdated(newEmissionRate);
    }

    /**
     * @notice Allows the owner to update the treasury address.
     * @param newTreasury The new treasury address.
     */
    function updateTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid treasury address");
        treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }
}
