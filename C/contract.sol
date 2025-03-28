// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title TermContract
/// @notice This contract models a dynamic legal agreement between two parties.  
/// PartyA (the contract deployer) and PartyB (the counterparty) agree on terms that can be updated by partyA  
/// until partyB accepts them. Once agreed, both parties may deposit funds into escrow, and upon reaching  
/// a deadline (or other conditions), the contract can be completed (with funds distributed) or cancelled.
contract TermContract is Ownable, ReentrancyGuard {
    // The two parties involved in the agreement.
    address public partyA; // Contract deployer
    address public partyB; // Counterparty

    // The state of the contract.
    enum ContractState { Created, Active, Completed, Cancelled }
    ContractState public state;

    // Terms structure holds the agreement details.
    struct Terms {
        string description; // Terms description
        uint256 deadline;   // Deadline timestamp for contract completion
        uint256 payment;    // Payment amount required (in wei)
        bool agreed;        // True when partyB has accepted the terms
    }
    Terms public terms;

    // Escrow deposits from both parties.
    mapping(address => uint256) public deposits;

    // --- Events ---
    event ContractInitialized(address indexed partyA, address indexed partyB, string description, uint256 deadline, uint256 payment);
    event TermsUpdated(string description, uint256 deadline, uint256 payment);
    event AgreementAccepted();
    event DepositMade(address indexed party, uint256 amount);
    event ContractCompleted();
    event ContractCancelled();

    /// @notice Initializes the contract with the counterparty and initial terms.
    /// @param _partyB The counterparty's address.
    /// @param _description The initial terms description.
    /// @param _deadline The deadline timestamp (must be in the future).
    /// @param _payment The payment amount required (in wei).
    constructor(
        address _partyB,
        string memory _description,
        uint256 _deadline,
        uint256 _payment
    ) Ownable(msg.sender) {
        require(_partyB != address(0), "Invalid partyB address");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        partyA = msg.sender;
        partyB = _partyB;
        terms = Terms({
            description: _description,
            deadline: _deadline,
            payment: _payment,
            agreed: false
        });
        state = ContractState.Created;
        emit ContractInitialized(partyA, partyB, _description, _deadline, _payment);
    }

    /// @notice Restricts functions to only partyA or partyB.
    modifier onlyParties() {
        require(msg.sender == partyA || msg.sender == partyB, "Not authorized");
        _;
    }

    /// @notice Allows partyA to update the terms if the contract is not yet active.
    /// Updating terms resets any previous acceptance.
    /// @param _description The new terms description.
    /// @param _deadline The new deadline timestamp.
    /// @param _payment The new payment amount.
    function updateTerms(
        string calldata _description,
        uint256 _deadline,
        uint256 _payment
    ) external onlyParties {
        require(state == ContractState.Created, "Contract not updateable");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        // For this example, we allow partyA to update the terms.
        // You could restrict this to only partyA if desired.
        require(msg.sender == partyA, "Only partyA can update terms");
        terms.description = _description;
        terms.deadline = _deadline;
        terms.payment = _payment;
        terms.agreed = false;
        emit TermsUpdated(_description, _deadline, _payment);
    }

    /// @notice Allows partyB to accept the current terms.
    function acceptTerms() external onlyParties nonReentrant {
        require(state == ContractState.Created, "Not in a state to accept");
        require(!terms.agreed, "Terms already accepted");
        require(msg.sender == partyB, "Only partyB can accept");
        terms.agreed = true;
        state = ContractState.Active;
        emit AgreementAccepted();
    }

    /// @notice Allows either party to deposit funds into escrow once the contract is active.
    /// Deposits are recorded against the sender's address.
    function deposit() external payable onlyParties nonReentrant {
        require(state == ContractState.Active, "Contract not active");
        require(msg.value > 0, "Deposit must be > 0");
        deposits[msg.sender] += msg.value;
        emit DepositMade(msg.sender, msg.value);
    }

    /// @notice Completes the contract after the deadline, assuming the required payment has been met.
    /// In a real implementation, funds distribution would be defined.
    function completeContract() external onlyParties nonReentrant {
        require(state == ContractState.Active, "Contract not active");
        require(block.timestamp >= terms.deadline, "Deadline not reached");
        uint256 totalDeposits = deposits[partyA] + deposits[partyB];
        require(totalDeposits >= terms.payment, "Insufficient total deposits");
        state = ContractState.Completed;
        // Funds distribution logic would be implemented here.
        emit ContractCompleted();
    }

    /// @notice Cancels the contract. Only the owner (partyA) can cancel before completion.
    /// In a cancellation, funds could be refunded.
    function cancelContract() external onlyOwner nonReentrant {
        require(state == ContractState.Created || state == ContractState.Active, "Cannot cancel after completion");
        state = ContractState.Cancelled;
        // Refund logic would be implemented here.
        emit ContractCancelled();
    }
}
