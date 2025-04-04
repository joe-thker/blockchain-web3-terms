// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EtherealImprovementProposals {
    enum ProposalStatus { Pending, Approved, Rejected }

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        uint256 deadline;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalSubmitted(uint256 indexed id, address indexed proposer);
    event Voted(uint256 indexed id, address indexed voter, bool support);
    event ProposalFinalized(uint256 indexed id, ProposalStatus status);

    modifier onlyBeforeDeadline(uint256 id) {
        require(block.timestamp < proposals[id].deadline, "Voting closed");
        _;
    }

    modifier onlyAfterDeadline(uint256 id) {
        require(block.timestamp >= proposals[id].deadline, "Voting still open");
        _;
    }

    function submitProposal(string calldata title, string calldata description, uint256 durationInSeconds) external {
        require(durationInSeconds > 0, "Invalid duration");

        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            title: title,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Pending,
            deadline: block.timestamp + durationInSeconds
        });

        emit ProposalSubmitted(proposalCount, msg.sender);
    }

    function vote(uint256 id, bool support) external onlyBeforeDeadline(id) {
        Proposal storage p = proposals[id];
        require(!hasVoted[id][msg.sender], "Already voted");

        hasVoted[id][msg.sender] = true;
        if (support) {
            p.votesFor++;
        } else {
            p.votesAgainst++;
        }

        emit Voted(id, msg.sender, support);
    }

    function finalizeProposal(uint256 id) external onlyAfterDeadline(id) {
        Proposal storage p = proposals[id];
        require(p.status == ProposalStatus.Pending, "Already finalized");

        if (p.votesFor > p.votesAgainst) {
            p.status = ProposalStatus.Approved;
        } else {
            p.status = ProposalStatus.Rejected;
        }

        emit ProposalFinalized(id, p.status);
    }

    function getProposal(uint256 id) external view returns (Proposal memory) {
        return proposals[id];
    }
}
