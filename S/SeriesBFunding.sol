// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SeriesBFundingSuite
/// @notice Implements three Series B funding mechanisms: Priced Equity, Convertible Note, Tokenized Equity
abstract contract SeriesBBase {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Simple Reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// 1) Priced Equity Round
contract PricedEquity is SeriesBBase, ReentrancyGuard {
    uint public sharePrice;               // wei per share
    uint public totalCap;                 // max wei
    mapping(address => uint) public paid; // wei contributed

    constructor(uint _price, uint _cap) {
        sharePrice = _price;
        totalCap   = _cap;
    }

    // --- Attack: no cap or reentrancy checks
    function buyInsecure(uint shares) external payable {
        require(msg.value == shares * sharePrice, "Incorrect funds");
        // no cap check → could exceed totalCap
        // no nonReentrant → reentrancy possible
        paid[msg.sender] += msg.value;
    }

    // --- Defense: cap, per-investor limit, and reentrancy guard
    function buySecure(uint shares) external payable nonReentrant {
        uint cost = shares * sharePrice;
        require(msg.value == cost, "Incorrect funds");
        require(address(this).balance <= totalCap, "Cap reached");
        require(paid[msg.sender] + msg.value <= totalCap / 10, "Investor limit");
        paid[msg.sender] += msg.value;
    }
}

/// 2) Convertible Note Issuance
contract ConvertibleNote is SeriesBBase {
    struct Note { uint amount; uint timestamp; bool redeemed; }
    mapping(address => Note) public notes;
    uint public maturity;   // UNIX timestamp
    uint public rateBP;     // basis points per annum

    constructor(uint _maturity, uint _rateBP) {
        maturity = _maturity;
        rateBP   = _rateBP;
    }

    // --- Attack: no maturity or whitelist checks
    function investInsecure() external payable {
        // anyone can invest multiple times, redeem anytime
        notes[msg.sender] = Note({ amount: msg.value, timestamp: block.timestamp, redeemed: false });
    }

    // --- Defense: single invest per investor, maturity enforced
    function investSecure() external payable {
        require(notes[msg.sender].amount == 0, "Already invested");
        require(msg.value > 0, "Zero investment");
        notes[msg.sender] = Note({ amount: msg.value, timestamp: block.timestamp, redeemed: false });
    }

    // --- Attack: redeem anytime, no interest calc checks
    function redeemInsecure() external {
        Note storage n = notes[msg.sender];
        require(!n.redeemed && n.amount > 0, "No note");
        uint payout = n.amount + (n.amount * rateBP / 10000) * ((block.timestamp - n.timestamp) / 365 days);
        n.redeemed = true;
        payable(msg.sender).transfer(payout);
    }

    // --- Defense: enforce maturity and correct interest calculation
    function redeemSecure() external {
        Note storage n = notes[msg.sender];
        require(!n.redeemed && n.amount > 0, "No note");
        require(block.timestamp >= maturity, "Not matured");
        uint yearsElapsed = (block.timestamp - n.timestamp) / 365 days;
        uint interest = (n.amount * rateBP / 10000) * yearsElapsed;
        uint payout = n.amount + interest;
        n.redeemed = true;
        payable(msg.sender).transfer(payout);
    }
}

/// 3) Tokenized Equity Round (ERC20-like)
contract TokenizedEquity is SeriesBBase {
    string public name = "SeriesB Equity";
    string public symbol = "SBQ";
    uint8 public decimals = 18;
    uint public totalSupply;
    uint public mintCap;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    constructor(uint _mintCap) {
        mintCap = _mintCap;
    }

    // --- Attack: unrestricted minting → dilution
    function mintInsecure(address to, uint amount) external {
        // no onlyOwner, no cap check
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    // --- Defense: onlyOwner + cap enforcement
    function mintSecure(address to, uint amount) external onlyOwner {
        require(totalSupply + amount <= mintCap, "Cap exceeded");
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    // Basic ERC20 transfer (no callbacks)
    function transfer(address to, uint amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    // Safe approve to avoid front-running
    function approve(address spender, uint amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient");
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        require(balanceOf[from] >= amount && allowance[from][msg.sender] >= amount, "Not allowed");
        balanceOf[from]    -= amount;
        allowance[from][msg.sender] -= amount;
        balanceOf[to]      += amount;
        return true;
    }
}
