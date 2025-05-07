// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// @notice Simple multi-source TWAP oracle interface
interface ITWAP {
    function getTwapPrice() external view returns (uint256);
}

/// @notice Minimal ERC20-like interface
interface IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

//////////////////////////////////////////
// 1) Speculative Pool
//////////////////////////////////////////
contract SpecPool is ReentrancyGuard {
    ITWAP  public oracleA;
    ITWAP  public oracleB;
    IERC20 public share;
    uint256 public globalCap;
    mapping(address=>uint256) public userCap;

    constructor(ITWAP _a, ITWAP _b, IERC20 _share, uint256 _gcap, uint256 _ucap) {
        oracleA    = _a;
        oracleB    = _b;
        share      = _share;
        globalCap  = _gcap;
        userCap[address(_share)] = _ucap;
    }

    // --- Attack: mint shares at naive on-chain price, unlimited deposits
    function depositInsecure() external payable {
        uint256 price = uint256(block.timestamp) * 1;  // bogus price
        uint256 shares = msg.value * 1e18 / price;
        share.mint(msg.sender, shares);
    }

    // --- Defense: TWAP average + caps + CEI
    function depositSecure() external nonReentrant payable {
        require(address(this).balance <= globalCap, "Global cap reached");
        require(msg.value <= userCap[msg.sender],   "User cap reached");
        // compute TWAP average
        uint256 p1 = oracleA.getTwapPrice();
        uint256 p2 = oracleB.getTwapPrice();
        uint256 price = (p1 + p2) / 2;
        require(price > 0, "Invalid price");
        uint256 shares = msg.value * 1e18 / price;
        share.mint(msg.sender, shares);
    }

    // Withdraw (mirror logic omitted)
}

//////////////////////////////////////////
// 2) Leveraged Position
//////////////////////////////////////////
contract Leveraged is ReentrancyGuard {
    IERC20 public collateralToken;
    ITWAP  public priceOracle;
    struct Position { uint256 collateral; uint256 debt; }
    mapping(address=>Position) public positions;
    uint256 public imarginBP;  // e.g. 15000 = 150%
    uint256 public mmarginBP;  // e.g. 12500 = 125%

    constructor(IERC20 _col, ITWAP _po, uint256 _im, uint256 _mm) {
        collateralToken = _col;
        priceOracle     = _po;
        imarginBP = _im;
        mmarginBP = _mm;
    }

    // --- Attack: open position without margin check
    function openInsecure(uint256 borrowAmount) external {
        positions[msg.sender].debt = borrowAmount;
    }

    // --- Defense: enforce initial margin + CEI
    function openSecure(uint256 collateralAmt, uint256 borrowAmt) external nonReentrant {
        // transfer collateral first
        require(collateralToken.transferFrom(msg.sender, address(this), collateralAmt), "Coll transfer");
        uint256 price = priceOracle.getTwapPrice();
        uint256 collValue = collateralAmt * price / 1e18;
        require(collValue * 10000 >= borrowAmt * imarginBP, "Init margin");
        Position storage p = positions[msg.sender];
        p.collateral += collateralAmt;
        p.debt       += borrowAmt;
        // lend borrowAmt...
    }

    // Close & liquidation logic...
    function liquidate(address user) external nonReentrant {
        Position storage p = positions[user];
        uint256 price = priceOracle.getTwapPrice();
        uint256 collValue = p.collateral * price / 1e18;
        require(collValue * 10000 < p.debt * mmarginBP, "Healthy");
        // seize collateral...
        delete positions[user];
    }
}

//////////////////////////////////////////
// 3) Flash-Loan Speculator
//////////////////////////////////////////
contract FlashSpec is ReentrancyGuard {
    ITWAP public priceOracle;
    uint256 public flashFeeBP;   // e.g. 9 = 0.09%
    uint256 public minLoan;

    constructor(ITWAP _po, uint256 _feeBP, uint256 _min) {
        priceOracle = _po;
        flashFeeBP  = _feeBP;
        minLoan     = _min;
    }

    // --- Attack: zero-fee, no oracle sync
    function flashInsecure(uint256 amount) external {
        require(amount <= address(this).balance, "Avail");
        payable(msg.sender).transfer(amount);
        // user must return manually; no fee enforced
    }

    // --- Defense: require fee + price-impact limit + CEI
    function flashSecure(uint256 amount) external nonReentrant {
        require(amount >= minLoan, "Min loan");
        require(amount <= address(this).balance, "Avail");
        // price-impact guard: require lastOracleSync within X blocks (omitted)
        uint256 fee = amount * flashFeeBP / 10000;
        uint256 due = amount + fee;
        // send
        payable(msg.sender).transfer(amount);
        // on return, require contract balance bumped
        require(address(this).balance >= due, "Flash fee not paid");
        // fee retained
    }

    receive() external payable {}
}
