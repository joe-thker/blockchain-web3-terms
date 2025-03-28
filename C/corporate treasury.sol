// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title CorporateTreasury
/// @notice This contract manages a corporate treasury by holding funds (Ether and tokens)
/// and handling spending proposals. Authorized managers (set by the owner) can propose expenditures.
/// Each spending proposal includes a description, a recipient, an amount, and a scheduled execution time
/// (a timelock is applied). Once the timelock expires, the proposal can be executed (i.e. funds transferred).
contract CorporateTreasury is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Mapping to store authorized spending managers.
    mapping(address => bool) public isManager;
    address[] public managers;

    // Spending proposal structure.
    struct SpendingProposal {
        uint256 id;
        string description;
        address payable recipient;
        uint256 amount;
        uint256 proposedAt;
        uint256 executeAfter; // proposedAt + timelock delay
        bool executed;
        bool cancelled;
    }
    uint256 public nextProposalId;
    mapping(uint256 => SpendingProposal) public proposals;

    // Timelock delay in seconds (e.g., 1 day).
    uint256 public constant TIMELOCK = 1 days;

    // --- Events ---
    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);
    event ProposalCreated(
        uint256 indexed proposalId,
        string description,
        address indexed recipient,
        uint256 amount,
        uint256 executeAfter
    );
    event ProposalCancelled(uint256 indexed proposalId);
    event ProposalExecuted(
        uint256 indexed proposalId,
        address indexed recipient,
        uint256 amount
    );
    event TokenTransferred(address indexed token, address indexed to, uint256 amount);
    event EtherReceived(address indexed sender, uint256 amount);

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {
        // Owner can add authorized managers later.
    }

    /// @notice Modifier to restrict functions to authorized managers or owner.
    modifier onlyManager() {
        require(isManager[msg.sender] || msg.sender == owner(), "Not authorized");
        _;
    }

    /// @notice Allows the owner to add an authorized manager.
    /// @param _manager The address to be added as a manager.
    function addManager(address _manager) external onlyOwner {
        require(_manager != address(0), "Invalid address");
        require(!isManager[_manager], "Already a manager");
        isManager[_manager] = true;
        managers.push(_manager);
        emit ManagerAdded(_manager);
    }

    /// @notice Allows the owner to remove an authorized manager.
    /// @param _manager The address to be removed.
    function removeManager(address _manager) external onlyOwner {
        require(isManager[_manager], "Not a manager");
        isManager[_manager] = false;
        // Remove from managers array.
        for (uint256 i = 0; i < managers.length; i++) {
            if (managers[i] == _manager) {
                managers[i] = managers[managers.length - 1];
                managers.pop();
                break;
            }
        }
        emit ManagerRemoved(_manager);
    }

    /// @notice Allows an authorized manager to propose a new expenditure.
    /// @param _description A description of the expenditure.
    /// @param _recipient The address to receive the funds.
    /// @param _amount The amount of Ether to be spent.
    /// @return proposalId The unique ID of the new proposal.
    function proposeExpenditure(
        string calldata _description,
        address payable _recipient,
        uint256 _amount
    ) external onlyManager nonReentrant returns (uint256 proposalId) {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Amount must be > 0");
        require(address(this).balance >= _amount, "Insufficient treasury balance");

        proposalId = nextProposalId;
        nextProposalId++;

        proposals[proposalId] = SpendingProposal({
            id: proposalId,
            description: _description,
            recipient: _recipient,
            amount: _amount,
            proposedAt: block.timestamp,
            executeAfter: block.timestamp + TIMELOCK,
            executed: false,
            cancelled: false
        });

        emit ProposalCreated(proposalId, _description, _recipient, _amount, block.timestamp + TIMELOCK);
    }

    /// @notice Allows an authorized manager or the owner to cancel a proposal that has not been executed.
    /// @param proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 proposalId) external onlyManager nonReentrant {
        SpendingProposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal already cancelled");

        proposal.cancelled = true;
        emit ProposalCancelled(proposalId);
    }

    /// @notice Allows an authorized manager or the owner to execute a proposal after the timelock has passed.
    /// @param proposalId The ID of the proposal to execute.
    /// @return result The return data from the fund transfer.
    function executeProposal(uint256 proposalId) external onlyManager nonReentrant returns (bytes memory result) {
        SpendingProposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal cancelled");
        require(block.timestamp >= proposal.executeAfter, "Timelock not expired");

        proposal.executed = true;
        (bool success, bytes memory res) = proposal.recipient.call{value: proposal.amount}("");
        require(success, "Fund transfer failed");
        result = res;

        emit ProposalExecuted(proposalId, proposal.recipient, proposal.amount);
    }

    /// @notice Allows the owner to transfer ERC20 tokens out of the treasury.
    /// @param token The ERC20 token to transfer.
    /// @param to The recipient address.
    /// @param amount The amount of tokens to transfer.
    function transferToken(IERC20 token, address to, uint256 amount) external onlyOwner nonReentrant {
        require(address(token) != address(0), "Invalid token address");
        require(to != address(0), "Invalid recipient address");
        token.safeTransfer(to, amount);
        emit TokenTransferred(address(token), to, amount);
    }

    /// @notice Fallback function to receive Ether.
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /// @notice Fallback function for non-empty calldata.
    fallback() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }
}
