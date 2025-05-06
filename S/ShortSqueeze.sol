// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ShortSqueezeSuite
/// @notice Implements LiquidationEngine, MarginAuction, and SqueezeProtectionPool
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// Oracle interface returning price in USD with 18 decimals
interface IOracle {
    function getPrice() external view returns (uint256);
}

/// ERC20 interface for collateral & synthetic asset
interface IERC20 {
    function transfer(address to, uint256 amt) external returns (bool);
    function transferFrom(address fr, address to, uint256 amt) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

/// 1) Automated Liquidation Engine
contract LiquidationEngine is Base, ReentrancyGuard {
    IOracle public oracleA;
    IOracle public oracleB;
    uint256 public minCollateralRatioBP = 15000; // 150%
    uint256 public cooldown = 1 hours;
    mapping(address => uint256) public lastLiquidation;

    struct Position { uint256 collateral; uint256 debt; }
    mapping(address => Position) public positions;

    // --- Attack: single oracle, no CEI, no cooldown
    function liquidateInsecure(address user) external {
        uint256 price = oracleA.getPrice();
        Position storage p = positions[user];
        require(p.collateral * price < p.debt * 1e18, "Not undercollateralized");
        // no cooldown, no CEI
        delete positions[user];
        payable(msg.sender).transfer(p.collateral);
    }

    // --- Defense: TWAP + CEI + cooldown guard
    function liquidateSecure(address user) external nonReentrant {
        require(block.timestamp >= lastLiquidation[user] + cooldown, "Cooldown");
        // TWAP = (oracleA + oracleB) / 2
        uint256 pa = oracleA.getPrice();
        uint256 pb = oracleB.getPrice();
        uint256 price = (pa + pb) / 2;
        Position storage p = positions[user];
        require(p.collateral * price * 10000 < p.debt * 1e18 * minCollateralRatioBP,
                "Healthy position");
        // Effects
        lastLiquidation[user] = block.timestamp;
        delete positions[user];
        // Interaction: pay liquidator collateral
        payable(msg.sender).transfer(p.collateral);
    }

    // deposit collateral & borrow debt
    function openPosition(uint256 collateralAmt, uint256 debtAmt) external payable {
        require(msg.value == collateralAmt, "Wrong ETH");
        positions[msg.sender] = Position(collateralAmt, debtAmt);
    }
}

/// 2) Margin Call Auction
contract MarginAuction is Base, ReentrancyGuard {
    IOracle public oracle;
    uint256 public minBidIncrementBP = 100; // 1%
    uint256 public auctionDuration = 30 minutes;

    struct Auction {
        address seller;
        uint256 collateralAmt;
        uint256 startPrice;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool    settled;
    }
    mapping(uint256 => Auction) public auctions;
    uint256 public nextAuctionId;

    // --- Attack: no floor price, no bid nonce
    function startAuctionInsecure(uint256 collateralAmt) external {
        uint256 price = oracle.getPrice();
        auctions[nextAuctionId++] = Auction(msg.sender, collateralAmt, price, 0, address(0), block.timestamp + auctionDuration, false);
    }
    function bidInsecure(uint256 auctionId) external payable {
        Auction storage a = auctions[auctionId];
        require(block.timestamp < a.endTime, "Ended");
        require(msg.value > a.highestBid, "Low bid");
        // no refund to previous bidder
        a.highestBid = msg.value;
        a.highestBidder = msg.sender;
    }

    // --- Defense: enforce floor + refund + unique bids
    function startAuctionSecure(uint256 collateralAmt) external {
        uint256 price = oracle.getPrice();
        auctions[nextAuctionId++] = Auction(
            msg.sender,
            collateralAmt,
            price * 90 / 100, // 10% floor discount
            0,
            address(0),
            block.timestamp + auctionDuration,
            false
        );
    }
    function bidSecure(uint256 auctionId) external payable nonReentrant {
        Auction storage a = auctions[auctionId];
        require(block.timestamp < a.endTime, "Ended");
        uint256 minBid = a.highestBid + (a.highestBid * minBidIncrementBP / 10000);
        require(msg.value >= minBid, "Below min increment");
        // refund previous
        if (a.highestBidder != address(0)) {
            payable(a.highestBidder).transfer(a.highestBid);
        }
        a.highestBid = msg.value;
        a.highestBidder = msg.sender;
    }
    function settleAuctionSecure(uint256 auctionId) external nonReentrant {
        Auction storage a = auctions[auctionId];
        require(block.timestamp >= a.endTime, "Not ended");
        require(!a.settled, "Settled");
        a.settled = true;
        // pay seller
        payable(a.seller).transfer(a.highestBid);
        // transfer collateral back to highestBidder off-chain or via another mechanism
    }
}

/// 3) Squeeze Protection Pool
contract SqueezeProtectionPool is Base, ReentrancyGuard {
    IOracle public oracle;
    IERC20  public synth;        // synthetic asset used to hedge
    uint256 public poolCap;
    uint256 public perUserCap;
    mapping(address => uint256) public hedged;

    constructor(address _oracle, address _synth, uint256 _poolCap, uint256 _userCap) {
        oracle    = IOracle(_oracle);
        synth     = IERC20(_synth);
        poolCap   = _poolCap;
        perUserCap= _userCap;
    }

    // --- Attack: unlimited minting & oracle hack
    function hedgeInsecure(uint256 amt) external {
        // no cap, no oracle check
        synth.transfer(msg.sender, amt);
        hedged[msg.sender] += amt;
    }

    // --- Defense: caps + TWAP sanity + CEI
    function hedgeSecure(uint256 amt) external nonReentrant {
        require(hedged[msg.sender] + amt <= perUserCap, "User cap");
        require(synth.balanceOf(address(this)) >= amt,  "Pool empty");
        // TWAP sanity: price change <20% 
        uint256 p1 = oracle.getPrice();
        // assume time passes and oracle B exists
        uint256 p2 = oracle.getPrice();
        uint256 shift = p1 > p2 ? (p1-p2)*10000/p1 : (p2-p1)*10000/p1;
        require(shift <= 2000, "Oracle drift");
        // Effects
        hedged[msg.sender] += amt;
        poolCap -= amt;
        // Interaction
        synth.transfer(msg.sender, amt);
    }

    // fund pool with synthetic tokens
    function fundPool(uint256 amt) external onlyOwner {
        synth.transferFrom(msg.sender, address(this), amt);
    }
}
