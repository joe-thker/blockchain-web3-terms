// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title LoanWithCosigner
/// @notice A simple loan contract that requires co-signers to guarantee the loan.
/// The contract distinguishes between Primary and Backup co-signers.
contract LoanWithCosigner {
    enum CoSignerType { Primary, Backup }

    struct CoSigner {
        address cosigner;
        CoSignerType cosignerType;
        bool signed;
    }

    address public borrower;
    uint256 public loanAmount;
    uint256 public repaymentAmount;
    bool public loanActive;

    // Array of required co-signers
    CoSigner[] public cosigners;

    event LoanCreated(address indexed borrower, uint256 loanAmount, uint256 repaymentAmount);
    event CoSignerSigned(address indexed cosigner, CoSignerType cosignerType);
    event LoanRepaid(address indexed borrower);

    modifier onlyBorrower() {
        require(msg.sender == borrower, "Caller is not the borrower");
        _;
    }

    modifier onlyCosigner() {
        bool isCosigner = false;
        for (uint256 i = 0; i < cosigners.length; i++) {
            if (cosigners[i].cosigner == msg.sender) {
                isCosigner = true;
                break;
            }
        }
        require(isCosigner, "Caller is not a co-signer");
        _;
    }

    /// @notice Constructor sets the borrower, loan details, and initializes co-signers.
    /// @param _borrower The address of the borrower.
    /// @param _loanAmount The loan amount.
    /// @param _repaymentAmount The total repayment amount.
    /// @param primaryCosigners An array of addresses for Primary co-signers.
    /// @param backupCosigners An array of addresses for Backup co-signers.
    constructor(
        address _borrower,
        uint256 _loanAmount,
        uint256 _repaymentAmount,
        address[] memory primaryCosigners,
        address[] memory backupCosigners
    ) {
        borrower = _borrower;
        loanAmount = _loanAmount;
        repaymentAmount = _repaymentAmount;
        loanActive = true;
        
        // Add primary co-signers.
        for (uint256 i = 0; i < primaryCosigners.length; i++) {
            cosigners.push(CoSigner({
                cosigner: primaryCosigners[i],
                cosignerType: CoSignerType.Primary,
                signed: false
            }));
        }
        // Add backup co-signers.
        for (uint256 i = 0; i < backupCosigners.length; i++) {
            cosigners.push(CoSigner({
                cosigner: backupCosigners[i],
                cosignerType: CoSignerType.Backup,
                signed: false
            }));
        }
        emit LoanCreated(_borrower, _loanAmount, _repaymentAmount);
    }

    /// @notice Allows a co-signer to sign the loan agreement.
    function signLoan() external onlyCosigner {
        for (uint256 i = 0; i < cosigners.length; i++) {
            if (cosigners[i].cosigner == msg.sender) {
                require(!cosigners[i].signed, "Already signed");
                cosigners[i].signed = true;
                emit CoSignerSigned(msg.sender, cosigners[i].cosignerType);
                break;
            }
        }
    }

    /// @notice Allows the borrower to repay the loan. (Simplified: no funds handling)
    function repayLoan() external onlyBorrower {
        require(loanActive, "Loan is not active");
        // In a full implementation, repayment funds would be transferred and verified.
        loanActive = false;
        emit LoanRepaid(msg.sender);
    }

    /// @notice Retrieves details of all co-signers.
    /// @return An array of CoSigner structs.
    function getCoSigners() external view returns (CoSigner[] memory) {
        return cosigners;
    }
}
