// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CeDeFiPlatform
/// @notice A simplified CeDeFi platform that allows users to deposit Ether,
/// earn simple interest over time, and withdraw their funds.
/// This contract simulates a centralized management layer with on-chain execution.
contract CeDeFiPlatform {
    address public owner;
    uint256 public interestRate; // Annual interest rate in basis points (1% = 100 basis points)
    bool public platformActive;

    // Structure to store each deposit's details.
    struct Deposit {
        uint256 amount;      // Amount of Ether deposited
        uint256 depositTime; // Timestamp when the deposit was made
        bool withdrawn;      // Whether the deposit has been withdrawn
    }

    // Mapping from a user's address to an array of their deposits.
    mapping(address => Deposit[]) public deposits;

    event DepositMade(address indexed user, uint256 amount, uint256 depositTime);
    event WithdrawalMade(address indexed user, uint256 principal, uint256 interest);
    event InterestRateUpdated(uint256 newInterestRate);
    event PlatformStatusChanged(bool active);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the deployer as the owner, the initial interest rate, and activates the platform.
    /// @param _interestRate Annual interest rate in basis points (e.g., 100 for 1%).
    constructor(uint256 _interestRate) {
        owner = msg.sender;
        interestRate = _interestRate;
        platformActive = true;
    }

    /// @notice Allows the owner to update the annual interest rate.
    /// @param _newInterestRate The new interest rate in basis points.
    function updateInterestRate(uint256 _newInterestRate) external onlyOwner {
        interestRate = _newInterestRate;
        emit InterestRateUpdated(_newInterestRate);
    }

    /// @notice Allows the owner to toggle the platform's active status.
    function togglePlatformStatus() external onlyOwner {
        platformActive = !platformActive;
        emit PlatformStatusChanged(platformActive);
    }

    /// @notice Allows users to deposit Ether into the platform.
    function deposit() external payable {
        require(platformActive, "Platform is not active");
        require(msg.value > 0, "Must deposit > 0 Ether");

        deposits[msg.sender].push(Deposit({
            amount: msg.value,
            depositTime: block.timestamp,
            withdrawn: false
        }));
        emit DepositMade(msg.sender, msg.value, block.timestamp);
    }

    /// @notice Calculates the simple interest for a deposit.
    /// @param principal The deposited amount.
    /// @param depositTime The time when the deposit was made.
    /// @return interest The accrued interest.
    function calculateInterest(uint256 principal, uint256 depositTime) public view returns (uint256 interest) {
        // Simple interest formula: interest = principal * rate * time / (365 days * 10000)
        uint256 timeElapsed = block.timestamp - depositTime;
        interest = (principal * interestRate * timeElapsed) / (365 days * 10000);
    }

    /// @notice Allows a user to withdraw a specific deposit along with the accrued interest.
    /// @param index The index of the deposit to withdraw.
    function withdraw(uint256 index) external {
        require(index < deposits[msg.sender].length, "Invalid deposit index");
        Deposit storage userDeposit = deposits[msg.sender][index];
        require(!userDeposit.withdrawn, "Deposit already withdrawn");

        uint256 interest = calculateInterest(userDeposit.amount, userDeposit.depositTime);
        uint256 totalAmount = userDeposit.amount + interest;
        userDeposit.withdrawn = true;

        (bool success, ) = msg.sender.call{value: totalAmount}("");
        require(success, "Withdrawal failed");

        emit WithdrawalMade(msg.sender, userDeposit.amount, interest);
    }

    /// @notice Retrieves all deposits of a user.
    /// @param user The address of the user.
    /// @return The array of deposits.
    function getDeposits(address user) external view returns (Deposit[] memory) {
        return deposits[user];
    }
}
