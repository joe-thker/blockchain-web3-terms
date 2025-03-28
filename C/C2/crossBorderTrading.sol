// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title CreditRatingSystem
/// @notice This contract manages credit scores for borrowers. Only the owner can update the credit score.
/// Credit scores are stored as dynamic values between MIN_CREDIT_SCORE and MAX_CREDIT_SCORE.
contract CreditRatingSystem is Ownable, ReentrancyGuard {
    // Define minimum and maximum credit scores.
    uint256 public constant MIN_CREDIT_SCORE = 300;
    uint256 public constant MAX_CREDIT_SCORE = 850;

    // Mapping from borrower address to their credit score.
    mapping(address => uint256) public creditScores;

    event CreditScoreUpdated(address indexed borrower, uint256 newCreditScore);

    /// @notice Updates the credit score for a given borrower.
    /// @param borrower The address of the borrower.
    /// @param newScore The new credit score; must be between MIN_CREDIT_SCORE and MAX_CREDIT_SCORE.
    function updateCreditScore(address borrower, uint256 newScore) external onlyOwner nonReentrant {
        require(newScore >= MIN_CREDIT_SCORE && newScore <= MAX_CREDIT_SCORE, "Credit score out of range");
        creditScores[borrower] = newScore;
        emit CreditScoreUpdated(borrower, newScore);
    }

    /// @notice Retrieves the credit score of a borrower.
    /// @param borrower The address of the borrower.
    /// @return The current credit score.
    function getCreditScore(address borrower) external view returns (uint256) {
        return creditScores[borrower];
    }
}
