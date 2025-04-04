// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EtherealRequestForComment {
    enum Status { Draft, Accepted, Rejected }

    struct ERCProposal {
        uint256 id;
        address author;
        string title;
        string content;
        Status status;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
    }

    struct Comment {
        address commenter;
        string text;
        uint256 timestamp;
    }

    uint256 public proposalCount;
    mapping(uint256 => ERCProposal) public proposals;
    mapping(uint256 => Comment[]) public proposalComments;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalSubmitted(uint256 indexed id, address indexed author, string title);
    event Voted(uint256 indexed id, address voter, bool support);
    event Finalized(uint256 indexed id, Status status);
    event CommentAdded(uint256 indexed id, address commenter, string text);

    modifier onlyBeforeDeadline(uint256 id) {
        require(block.timestamp < proposals[id].deadline, "Voting closed");
        _;
    }

    modifier onlyAfterDeadline(uint256 id) {
        require(block.timestamp >= proposals[id].deadline, "Voting open");
        _;
    }

    function submitProposal(
        string calldata title,
        string calldata content,
        uint256 duration
    ) external {
        require(duration > 0, "Invalid duration");

        proposalCount++;
        proposals[proposalCount] = ERCProposal({
            id: proposalCount,
            author: msg.sender,
            title: title,
            content: content,
            status: Status.Draft,
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp + duration
        });

        emit ProposalSubmitted(proposalCount, msg.sender, title);
    }

    function vote(uint256 id, bool support) external onlyBeforeDeadline(id) {
        require(!hasVoted[id][msg.sender], "Already voted");
        ERCProposal storage p = proposals[id];

        if (support) {
            p.votesFor++;
        } else {
            p.votesAgainst++;
        }

        hasVoted[id][msg.sender] = true;
        emit Voted(id, msg.sender, support);
    }

    function finalize(uint256 id) external onlyAfterDeadline(id) {
        ERCProposal storage p = proposals[id];
        require(p.status == Status.Draft, "Already finalized");

        if (p.votesFor > p.votesAgainst) {
            p.status = Status.Accepted;
        } else {
            p.status = Status.Rejected;
        }

        emit Finalized(id, p.status);
    }

    function comment(uint256 id, string calldata text) external {
        require(bytes(text).length > 0, "Empty comment");
        proposalComments[id].push(Comment({
            commenter: msg.sender,
            text: text,
            timestamp: block.timestamp
        }));

        emit CommentAdded(id, msg.sender, text);
    }

    function getProposal(uint256 id) external view returns (ERCProposal memory) {
        return proposals[id];
    }

    function getComments(uint256 id) external view returns (Comment[] memory) {
        return proposalComments[id];
    }
}
