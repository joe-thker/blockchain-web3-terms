// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CertificateOfDeposit {
    // Enum for CD types: 0 = Short, 1 = Medium, 2 = Long
    enum CDType { Short, Medium, Long }

    // Structure to hold details of a deposit
    struct Deposit {
        uint256 amount;         // Amount of Ether deposited
        uint256 depositTime;    // Timestamp of deposit
        uint256 lockDuration;   // Lock duration in seconds
        uint256 interestRate;   // Interest rate in basis points per annum (1% = 100 basis points)
        bool withdrawn;         // Indicates if the deposit has been withdrawn
        CDType cdType;          // Type of the certificate
    }
    
    // Mapping of user addresses to their array of deposits
    mapping(address => Deposit[]) public deposits;

    // Predefined parameters for each CD type:
    uint256 public constant SHORT_LOCK = 90 days;
    uint256 public constant MEDIUM_LOCK = 180 days;
    uint256 public constant LONG_LOCK = 365 days;

    uint256 public constant SHORT_RATE = 300;   // 3% per annum (300 basis points)
    uint256 public constant MEDIUM_RATE = 500;    // 5% per annum (500 basis points)
    uint256 public constant LONG_RATE = 700;      // 7% per annum (700 basis points)

    // Events for logging deposits and withdrawals
    event DepositMade(
        address indexed user,
        uint256 indexed depositIndex,
        CDType cdType,
        uint256 amount,
        uint256 depositTime,
        uint256 lockDuration,
        uint256 interestRate
    );
    event Withdrawal(
        address indexed user,
        uint256 indexed depositIndex,
        uint256 principal,
        uint256 interest
    );

    /// @notice Allows a user to deposit Ether into a CD of a specified type.
    /// @param cdTypeValue The type of CD (0 for Short, 1 for Medium, 2 for Long).
    function deposit(uint8 cdTypeValue) external payable {
        require(msg.value > 0, "Deposit must be > 0 Ether");
        require(cdTypeValue < 3, "Invalid CD type");

        CDType cdType = CDType(cdTypeValue);
        uint256 lockDuration;
        uint256 interestRate;

        if (cdType == CDType.Short) {
            lockDuration = SHORT_LOCK;
            interestRate = SHORT_RATE;
        } else if (cdType == CDType.Medium) {
            lockDuration = MEDIUM_LOCK;
            interestRate = MEDIUM_RATE;
        } else if (cdType == CDType.Long) {
            lockDuration = LONG_LOCK;
            interestRate = LONG_RATE;
        }

        deposits[msg.sender].push(Deposit({
            amount: msg.value,
            depositTime: block.timestamp,
            lockDuration: lockDuration,
            interestRate: interestRate,
            withdrawn: false,
            cdType: cdType
        }));

        uint256 depositIndex = deposits[msg.sender].length - 1;
        emit DepositMade(msg.sender, depositIndex, cdType, msg.value, block.timestamp, lockDuration, interestRate);
    }

    /// @notice Calculates simple interest for a given deposit.
    /// @param principal The deposited amount.
    /// @param interestRate The annual interest rate in basis points.
    /// @param duration The duration in seconds that has passed since deposit.
    /// @return interest The calculated interest.
    function calculateInterest(uint256 principal, uint256 interestRate, uint256 duration) public pure returns (uint256 interest) {
        // Simple interest: interest = principal * rate * time / (365 days * 10000)
        interest = (principal * interestRate * duration) / (365 days * 10000);
    }

    /// @notice Allows a user to withdraw a matured deposit along with the accrued interest.
    /// @param depositIndex The index of the deposit to withdraw.
    function withdraw(uint256 depositIndex) external {
        require(depositIndex < deposits[msg.sender].length, "Invalid deposit index");
        Deposit storage d = deposits[msg.sender][depositIndex];
        require(!d.withdrawn, "Deposit already withdrawn");
        require(block.timestamp >= d.depositTime + d.lockDuration, "Deposit not matured");

        uint256 duration = block.timestamp - d.depositTime;
        uint256 interest = calculateInterest(d.amount, d.interestRate, duration);
        uint256 payout = d.amount + interest;

        d.withdrawn = true;

        (bool success, ) = msg.sender.call{value: payout}("");
        require(success, "Withdrawal failed");

        emit Withdrawal(msg.sender, depositIndex, d.amount, interest);
    }

    /// @notice Returns the total number of deposits for a given user.
    /// @param user The address of the user.
    /// @return The count of deposits.
    function getDepositCount(address user) external view returns (uint256) {
        return deposits[user].length;
    }
}
