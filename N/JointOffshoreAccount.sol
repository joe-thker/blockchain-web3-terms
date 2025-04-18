// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title JointOffshoreAccount
 * @notice Owners can deposit ETH. To withdraw, an owner creates a request;
 *         owners then approve it; once `threshold` approvals are reached,
 *         anyone may execute the withdrawal to a designated recipient.
 */
contract JointOffshoreAccount is Ownable {
    uint256 public requestCount;
    uint256 public threshold;
    mapping(address => bool) public isOwner;
    address[] public owners;

    struct Request {
        address proposer;
        address payable to;
        uint256 amount;
        uint256 approvals;
        bool executed;
        mapping(address => bool) approvedBy;
    }
    mapping(uint256 => Request) private requests;

    event Deposit(address indexed sender, uint256 amount);
    event WithdrawalRequested(uint256 indexed id, address indexed proposer, address to, uint256 amount);
    event Approved(uint256 indexed id, address indexed owner, uint256 approvals);
    event Executed(uint256 indexed id);

    modifier onlyOwnerModifier() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    /**
     * @param _owners    List of initial owners
     * @param _threshold Number of approvals required to execute
     */
    constructor(address[] memory _owners, uint256 _threshold)
        Ownable(msg.sender)
    {
        require(_owners.length >= _threshold && _threshold > 0, "Invalid threshold");
        threshold = _threshold;
        for (uint256 i = 0; i < _owners.length; i++) {
            address o = _owners[i];
            require(o != address(0), "Zero owner");
            require(!isOwner[o], "Duplicate owner");
            isOwner[o] = true;
            owners.push(o);
        }
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Propose a withdrawal from the pooled funds.
     * @param to     Recipient address
     * @param amount Amount of ETH to withdraw
     */
    function proposeWithdrawal(address payable to, uint256 amount) external onlyOwnerModifier {
        require(amount > 0 && amount <= address(this).balance, "Invalid amount");
        uint256 id = requestCount++;
        Request storage r = requests[id];
        r.proposer = msg.sender;
        r.to = to;
        r.amount = amount;
        emit WithdrawalRequested(id, msg.sender, to, amount);
    }

    /**
     * @notice Approve a pending withdrawal request.
     * @param id The request ID
     */
    function approve(uint256 id) external onlyOwnerModifier {
        Request storage r = requests[id];
        require(!r.executed, "Already executed");
        require(!r.approvedBy[msg.sender], "Already approved");
        r.approvedBy[msg.sender] = true;
        r.approvals += 1;
        emit Approved(id, msg.sender, r.approvals);
    }

    /**
     * @notice Execute a withdrawal once enough approvals are collected.
     * @param id The request ID
     */
    function execute(uint256 id) external {
        Request storage r = requests[id];
        require(!r.executed, "Already executed");
        require(r.approvals >= threshold, "Not enough approvals");
        r.executed = true;
        r.to.transfer(r.amount);
        emit Executed(id);
    }

    /// @notice Get the list of owners
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    /**
     * @notice Retrieve details of a withdrawal request.
     * @param id The request ID
     */
    function getRequest(uint256 id)
        external
        view
        returns (
            address proposer,
            address to,
            uint256 amount,
            uint256 approvals,
            bool executed
        )
    {
        Request storage r = requests[id];
        return (r.proposer, r.to, r.amount, r.approvals, r.executed);
    }
}
