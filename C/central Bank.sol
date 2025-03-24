// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin's ERC20 and Ownable implementations.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CentralBank
/// @notice This contract simulates a simplified central bank mechanism using an ERC20 token.
/// It allows the owner to manage the token supply (issue or reduce money) and set an interest rate.
contract CentralBank is ERC20, Ownable {
    // Interest rate in basis points (e.g., 500 = 5% per annum)
    uint256 public interestRate;

    event InterestRateUpdated(uint256 newRate);
    event MoneyIssued(address indexed to, uint256 amount);
    event MoneyReduced(address indexed from, uint256 amount);

    /// @notice Constructor initializes the central bank digital currency and sets the initial interest rate.
    /// @param initialSupply The initial supply of tokens (in the smallest unit, e.g., wei for 18 decimals).
    /// @param _interestRate The initial interest rate in basis points.
    constructor(uint256 initialSupply, uint256 _interestRate)
        ERC20("Central Bank Digital Currency", "CBDC")
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
        interestRate = _interestRate;
    }

    /// @notice Allows the owner to update the interest rate.
    /// @param newRate The new interest rate in basis points.
    function setInterestRate(uint256 newRate) external onlyOwner {
        interestRate = newRate;
        emit InterestRateUpdated(newRate);
    }

    /// @notice Allows the owner to issue (mint) new tokens to an account.
    /// @param to The address receiving the minted tokens.
    /// @param amount The amount of tokens to mint.
    function issueMoney(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit MoneyIssued(to, amount);
    }

    /// @notice Allows the owner to reduce (burn) tokens from a specified account.
    /// @param from The address from which tokens will be burned.
    /// @param amount The amount of tokens to burn.
    function reduceMoney(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
        emit MoneyReduced(from, amount);
    }
}
