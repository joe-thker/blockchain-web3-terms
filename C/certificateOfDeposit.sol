// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CertificateOfDeepDeposit
/// @notice A contract that simulates a certificate of deep deposit where users lock funds for an extended period to earn interest.
contract CertificateOfDeepDeposit {
    address public owner;

    // Structure to hold each deposit's details.
    struct Deposit {
        uint256 amount;         // Amount of Ether deposited.
        uint256 depositTime;    // Timestamp when the deposit was made.
        uint256 lockDuration;   // How long the deposit is locked (in seconds).
        uint256 interestRate;   // Interest rate in basis points (e.g., 500 means 5% per annum).
        bool withdrawn;         // Indicates if the deposit has been withdrawn.
    }
    
    // Mapping from a user's address to their deposits.
    mapping(address => Deposit[]) public deposits;

    // Events for logging deposits and withdrawals.
    event Deposited(address indexed user, uint256 indexed depositIndex, uint256 amount, uint256 lockDuration, uint256 interestRate);
    event Withdrawn(address indexed user, uint256 indexed depositIndex, uint256 principal, uint256 interest);

    // Minimum lock duration: for instance, 1 year.
    uint256 public constant MIN_LOCK_DURATION = 365 days;

    /// @notice Constructor sets the deployer as the contract owner.
    constructor() {
        owner = msg.sender;
    }

    /// @notice Allows a user to deposit Ether as a Certificate of Deep Deposit.
    /// @param lockDuration The duration for which funds will be locked. Must be at least MIN_LOCK_DURATION.
    /// @dev For simplicity, the interest rate is fixed at 5% per annum (500 basis points).
    function deposit(uint256 lockDuration) external payable {
        require(msg.value > 0, "Deposit must be > 0");
        require(lockDuration >= MIN_LOCK_DURATION, "Lock duration must be at least 1 year");

        // Fixed interest rate: 5% per annum.
        uint256 interestRate = 500; // 500 basis points = 5%

        deposits[msg.sender].push(Deposit({
            amount: msg.value,
            depositTime: block.timestamp,
            lockDuration: lockDuration,
            interestRate: interestRate,
            withdrawn: false
        }));

        uint256 depositIndex = deposits[msg.sender].length - 1;
        emit Deposited(msg.sender, depositIndex, msg.value, lockDuration, interestRate);
    }

    /// @notice Calculates simple interest for a deposit.
    /// @param principal The deposit amount.
    /// @param interestRate The interest rate in basis points.
    /// @param duration The duration in seconds the funds have been locked.
    /// @return interest The calculated interest amount.
    function calculateInterest(uint256 principal, uint256 interestRate, uint256 duration) public pure returns (uint256 interest) {
        // Simple interest formula:
        // interest = principal * interestRate * duration / (365 days * 10000)
        interest = (principal * interestRate * duration) / (365 days * 10000);
    }

    /// @notice Allows a user to withdraw their matured deposit along with accrued interest.
    /// @param depositIndex The index of the deposit to withdraw.
    function withdraw(uint256 depositIndex) external {
        require(depositIndex < deposits[msg.sender].length, "Invalid deposit index");
        Deposit storage userDeposit = deposits[msg.sender][depositIndex];
        require(!userDeposit.withdrawn, "Deposit already withdrawn");
        require(block.timestamp >= userDeposit.depositTime + userDeposit.lockDuration, "Deposit not matured");

        uint256 duration = block.timestamp - userDeposit.depositTime;
        uint256 interest = calculateInterest(userDeposit.amount, userDeposit.interestRate, duration);
        uint256 payout = userDeposit.amount + interest;
        userDeposit.withdrawn = true;

        (bool success, ) = msg.sender.call{value: payout}("");
        require(success, "Withdrawal failed");

        emit Withdrawn(msg.sender, depositIndex, userDeposit.amount, interest);
    }

    /// @notice Retrieves all deposits of a given user.
    /// @param user The address of the user.
    /// @return An array of Deposit structs.
    function getDeposits(address user) external view returns (Deposit[] memory) {
        return deposits[user];
    }
}
