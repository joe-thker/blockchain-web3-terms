// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ITWAP {
    function getTwapPrice() external view returns (uint256);
}

////////////////////////////////////////////////////////////////////////////////
// 1) Uncontrolled Mint Rate
////////////////////////////////////////////////////////////////////////////////
contract InflationaryToken {
    string public name = "StagToken";
    string public symbol = "STAG";
    uint8  public decimals = 18;

    uint256 public totalSupply;
    mapping(address=>uint256) public balanceOf;

    address public owner;
    uint256 public cap;             // global max supply
    uint256 public perMintLimit;    // max per mint
    uint256 public lastMintTime;
    uint256 public mintCooldown;    // e.g. 1 day

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
    modifier mintAllowed(uint256 amt) {
        require(amt <= perMintLimit, "Exceeds per-mint limit");
        require(block.timestamp >= lastMintTime + mintCooldown, "Cooldown");
        require(totalSupply + amt <= cap, "Cap exceeded");
        _;
    }

    constructor(uint256 _cap, uint256 _perMint, uint256 _cooldown) {
        owner          = msg.sender;
        cap            = _cap;
        perMintLimit   = _perMint;
        mintCooldown   = _cooldown;
    }

    // --- Attack: unrestricted mint
    function mintInsecure(address to, uint256 amt) external {
        // no checks at all
        balanceOf[to]    += amt;
        totalSupply      += amt;
    }

    // --- Defense: onlyOwner + per-mint limit + cooldown + cap
    function mintSecure(address to, uint256 amt) external onlyOwner mintAllowed(amt) {
        balanceOf[to]    += amt;
        totalSupply      += amt;
        lastMintTime     = block.timestamp;
    }
}

////////////////////////////////////////////////////////////////////////////////
// 2) Fixed Staking Rewards
////////////////////////////////////////////////////////////////////////////////
contract StakingRewards is ReentrancyGuard {
    Inflatio­naryToken public token;
    address            public owner;
    uint256            public epochDuration;    // e.g. 1 week
    uint256            public lastEpoch;
    uint256            public rewardPerEpoch;   // fixed amount

    mapping(address=>uint256) public stakeBalance;
    uint256 public totalStaked;

    modifier onlyOwner() { require(msg.sender==owner,"Not owner"); _; }

    constructor(address _token, uint256 _epochDur, uint256 _reward) {
        token          = InflationaryToken(_token);
        owner          = msg.sender;
        epochDuration  = _epochDur;
        rewardPerEpoch = _reward;
        lastEpoch      = block.timestamp;
    }

    // --- Attack: issue rewards even if treasury empty or no stake
    function issueRewardsInsecure() external {
        // simply mints rewards to all stakers evenly
        token.mintInsecure(address(this), rewardPerEpoch);
        // distribute...
    }

    // --- Defense: check treasury, adjust to totalStaked
    function issueRewardsSecure() external onlyOwner {
        require(block.timestamp >= lastEpoch + epochDuration, "Epoch not ended");
        require(totalStaked > 0, "No stakes");
        // cap reward by token cap / treasury balance
        uint256 treasuryBal = token.balanceOf(address(this));
        uint256 reward = rewardPerEpoch;
        if (reward > treasuryBal) reward = treasuryBal;
        // dynamic adjustment: scale by totalStaked (example)
        uint256 perToken = reward * 1e18 / totalStaked;
        // mint once
        token.mintSecure(address(this), reward);
        // distribute linearly...
        // e.g. for each staker: stakeBalance[user]*perToken/1e18
        lastEpoch = block.timestamp;
    }

    // stake/unstake omitted for brevity
}

////////////////////////////////////////////////////////////////////////////////
// 3) Oracle-Based Supply Adjustment (Rebase)
////////////////////////////////////////////////////////////////////////////////
contract RebaseMechanism is ReentrancyGuard {
    string public name = "RebaseSTAG";
    mapping(address=>uint256) public balanceOf;
    uint256 public totalSupply;

    address public owner;
    ITWAP   public oracleA;
    ITWAP   public oracleB;
    uint256 public lastRebase;
    uint256 public rebaseCooldown; // e.g. 1 day
    uint256 public minSupply;
    uint256 public maxSupply;

    modifier onlyOwner() { require(msg.sender==owner,"Not owner"); _; }
    modifier canRebase() {
        require(block.timestamp>=lastRebase+rebaseCooldown,"Cooldown");
        _;
    }

    constructor(
        address _a, address _b,
        uint256 _cool, uint256 _min, uint256 _max
    ) {
        owner           = msg.sender;
        oracleA         = ITWAP(_a);
        oracleB         = ITWAP(_b);
        rebaseCooldown  = _cool;
        minSupply       = _min;
        maxSupply       = _max;
    }

    // --- Attack: anyone can spam rebase with manipulated price
    function rebaseInsecure(int256 delta) external {
        totalSupply = uint256(int256(totalSupply) + delta);
        // naive balance adjustments...
        lastRebase = block.timestamp;
    }

    // --- Defense: onlyOwner + cooldown + TWAP aggregate + bounds
    function rebaseSecure(int256 delta) external onlyOwner canRebase {
        // TWAP average
        uint256 p1 = oracleA.getTwapPrice();
        uint256 p2 = oracleB.getTwapPrice();
        uint256 price = (p1 + p2) / 2;
        require(price > 0, "Invalid price");
        // supply bounds
        int256 newSupply = int256(totalSupply) + delta;
        require(newSupply >= int256(minSupply) && newSupply <= int256(maxSupply), "Out of bounds");
        totalSupply = uint256(newSupply);
        // proportional balance adjust omitted for brevity
        lastRebase = block.timestamp;
    }
}
