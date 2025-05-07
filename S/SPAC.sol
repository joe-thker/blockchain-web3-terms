// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Base {
    address public owner;
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
    constructor() { owner = msg.sender; }
}

abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

//////////////////////////////////////////////////////
// 1) SPAC Token Issuance & Redemption
//////////////////////////////////////////////////////
contract SPACShares is Base, ReentrancyGuard {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    uint256 public cap;
    uint256 public redemptionDeadline;

    constructor(uint256 _cap, uint256 _deadline) {
        cap = _cap;
        redemptionDeadline = _deadline;
    }

    // --- Attack: anyone mints without deposit, unlimited
    function mintInsecure(uint256 shares) external {
        balanceOf[msg.sender] += shares;
        totalSupply += shares;
    }

    // --- Defense: mint 1:1 with ETH deposit + cap
    function mintSecure() external payable {
        uint256 shares = msg.value;
        require(totalSupply + shares <= cap, "Cap exceeded");
        balanceOf[msg.sender] += shares;
        totalSupply += shares;
    }

    // --- Attack: reentrant redemption drains contract
    function redeemInsecure(uint256 shares) external {
        require(balanceOf[msg.sender] >= shares, "Insufficient");
        // no effects before call
        payable(msg.sender).transfer(shares);
        balanceOf[msg.sender] -= shares;
    }

    // --- Defense: CEI + nonReentrant + deadline
    function redeemSecure(uint256 shares) external nonReentrant {
        require(block.timestamp <= redemptionDeadline, "Redemption closed");
        require(balanceOf[msg.sender] >= shares, "Insufficient");
        // Effects
        balanceOf[msg.sender] -= shares;
        totalSupply -= shares;
        // Interaction
        payable(msg.sender).transfer(shares);
    }

    receive() external payable {}
}

//////////////////////////////////////////////////////
// 2) SPAC Governance DAO
//////////////////////////////////////////////////////
contract SPACGovernance is Base {
    SPACShares public shares;
    uint256 public proposalCount;
    uint256 public minDeposit;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public voted;
    mapping(address => uint256) public lastProposalAt;

    struct Proposal {
        address proposer;
        string   description;
        uint256  snapshotBlock;
        uint256  votesFor;
        uint256  deposit;
        bool     executed;
    }

    constructor(address shareToken, uint256 _minDeposit) {
        shares = SPACShares(shareToken);
        minDeposit = _minDeposit;
    }

    // --- Attack: anyone creates spam proposals or without deposit
    function proposeInsecure(string calldata desc) external {
        proposals[++proposalCount] = Proposal(msg.sender, desc, block.number, 0, 0, false);
    }

    // --- Defense: require deposit + rate-limit + snapshot
    function proposeSecure(string calldata desc) external payable {
        require(msg.value >= minDeposit, "Deposit too low");
        require(block.timestamp >= lastProposalAt[msg.sender] + 1 days, "Rate limited");
        lastProposalAt[msg.sender] = block.timestamp;
        uint256 id = ++proposalCount;
        proposals[id] = Proposal(
            msg.sender,
            desc,
            block.number,    // snapshot current block
            0,
            msg.value,
            false
        );
    }

    // --- Attack: vote any time, multiple times
    function voteInsecure(uint256 id) external {
        uint256 weight = shares.balanceOf(msg.sender);
        proposals[id].votesFor += weight;
    }

    // --- Defense: snapshot balance + one‐vote per address
    function voteSecure(uint256 id) external {
        Proposal storage p = proposals[id];
        require(!p.executed, "Executed");
        require(!voted[id][msg.sender], "Already voted");
        uint256 weight = SPACShares(address(shares)).balanceAtSecure(msg.sender, p.snapshotBlock);
        // assumes SPACShares has balanceAtSecure like earlier example
        require(weight > 0, "No voting power");
        p.votesFor += weight;
        voted[id][msg.sender] = true;
    }

    // helper to withdraw failed-proposal deposit
    function withdrawDeposit(uint256 id) external {
        Proposal storage p = proposals[id];
        require(p.proposer == msg.sender, "Not proposer");
        require(block.timestamp > p.snapshotBlock + 7 days, "Too soon");
        require(!p.executed, "Already executed");
        uint256 dep = p.deposit;
        p.deposit = 0;
        payable(msg.sender).transfer(dep);
    }
}

//////////////////////////////////////////////////////
// 3) SPAC Merger Execution
//////////////////////////////////////////////////////
contract SPACMerger is Base, ReentrancyGuard {
    SPACShares    public shares;
    SPACGovernance public gov;
    uint256       public requiredQuorum;
    bool          public merged;
    bytes32       public expectedTargetCodeHash;

    event Merged(address target);

    constructor(
        address shareToken,
        address governance,
        uint256 quorum,
        bytes32 targetCodeHash
    ) {
        shares = SPACShares(shareToken);
        gov    = SPACGovernance(governance);
        requiredQuorum = quorum;
        expectedTargetCodeHash = targetCodeHash;
    }

    // --- Attack: anyone triggers merge prematurely or replay
    function mergeInsecure(address target) external {
        require(!merged, "Already merged");
        // no vote or code checks
        (bool ok,) = target.call{value: address(this).balance}("");
        require(ok, "Merge call failed");
        merged = true;
        emit Merged(target);
    }

    // --- Defense: onlyOwner/multisig + quorum + codehash + nonReentrant
    function mergeSecure(address target) external onlyOwner nonReentrant {
        require(!merged, "Already merged");
        // check quorum reached
        (, , , uint256 votesFor, , bool executed) = gov.proposals(gov.proposalCount());
        require(votesFor >= requiredQuorum, "Quorum not reached");
        require(!executed, "Proposal executed");
        // verify target code
        bytes32 actual;
        assembly { actual := extcodehash(target) }
        require(actual == expectedTargetCodeHash, "Bad target");
        // execute merger
        (bool ok,) = target.call{value: address(this).balance}("");
        require(ok, "Merge call failed");
        merged = true;
        emit Merged(target);
    }

    // fallback to accept any funds until merger
    receive() external payable {}
}
