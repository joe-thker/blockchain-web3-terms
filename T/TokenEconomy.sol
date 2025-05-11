// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TokenEconomyModule - Token Economy Framework (ERC20 + Staking + Governance + Treasury)

/// ------------------------------------
/// 🪙 EconomyToken (ERC20 + Mint/Burn + Cap)
/// ------------------------------------
contract EconomyToken {
    string public name = "EconToken";
    string public symbol = "ECON";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public immutable cap;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    address public admin;

    constructor(uint256 _cap) {
        cap = _cap;
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    function mint(address to, uint256 amt) external onlyAdmin {
        require(totalSupply + amt <= cap, "Cap exceeded");
        totalSupply += amt;
        balances[to] += amt;
    }

    function burn(uint256 amt) external {
        require(balances[msg.sender] >= amt, "Insufficient");
        balances[msg.sender] -= amt;
        totalSupply -= amt;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Balance too low");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function approve(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        return true;
    }

    function transferFrom(address from, address to, uint256 amt) external returns (bool) {
        require(balances[from] >= amt && allowance[from][msg.sender] >= amt, "Not allowed");
        balances[from] -= amt;
        balances[to] += amt;
        allowance[from][msg.sender] -= amt;
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

/// ------------------------------------
/// 🏦 StakingVault (Time-Based Rewards)
/// ------------------------------------
contract StakingVault {
    EconomyToken public token;
    uint256 public constant RATE = 10 ether / 1 days;

    struct Stake {
        uint256 amount;
        uint256 since;
        uint256 reward;
    }

    mapping(address => Stake) public stakes;

    constructor(address _token) {
        token = EconomyToken(_token);
    }

    function stake(uint256 amt) external {
        require(token.transferFrom(msg.sender, address(this), amt), "Stake failed");
        Stake storage s = stakes[msg.sender];

        if (s.amount > 0) {
            s.reward += earned(msg.sender);
        }

        s.amount += amt;
        s.since = block.timestamp;
    }

    function earned(address user) public view returns (uint256) {
        Stake memory s = stakes[user];
        if (s.amount == 0) return 0;
        return ((block.timestamp - s.since) * RATE * s.amount) / 1 ether;
    }

    function withdraw() external {
        Stake storage s = stakes[msg.sender];
        uint256 total = s.amount + s.reward + earned(msg.sender);
        s.amount = 0;
        s.reward = 0;
        token.mint(msg.sender, total);
    }
}

/// ------------------------------------
/// 🗳️ TokenGovernance (Snapshot Voting)
/// ------------------------------------
contract TokenGovernance {
    EconomyToken public token;
    struct Proposal {
        string description;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) voted;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    constructor(address _token) {
        token = EconomyToken(_token);
    }

    function propose(string calldata desc) external {
        Proposal storage p = proposals[proposalCount++];
        p.description = desc;
        p.deadline = block.timestamp + 3 days;
    }

    function vote(uint256 id, bool support) external {
        Proposal storage p = proposals[id];
        require(block.timestamp < p.deadline, "Ended");
        require(!p.voted[msg.sender], "Already voted");

        uint256 weight = token.balanceOf(msg.sender);
        require(weight > 0, "No tokens");

        if (support) p.votesFor += weight;
        else p.votesAgainst += weight;

        p.voted[msg.sender] = true;
    }

    function execute(uint256 id) external {
        Proposal storage p = proposals[id];
        require(block.timestamp >= p.deadline, "Too early");
        require(!p.executed, "Already executed");
        p.executed = true;
        // outcome based on votes (example only)
    }
}

/// ------------------------------------
/// 💰 Treasury (Time-Locked Withdrawals)
/// ------------------------------------
contract Treasury {
    EconomyToken public token;
    address public admin;
    uint256 public unlockTime;

    constructor(address _token, uint256 delaySeconds) {
        token = EconomyToken(_token);
        admin = msg.sender;
        unlockTime = block.timestamp + delaySeconds;
    }

    function withdraw(address to, uint256 amt) external {
        require(msg.sender == admin, "Not admin");
        require(block.timestamp >= unlockTime, "Timelocked");
        token.transfer(to, amt);
    }
}
