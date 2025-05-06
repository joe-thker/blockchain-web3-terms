// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ShortSuite
/// @notice Implements MarginShort, SyntheticShort, and PerpShort modules
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
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

/// Interface for ERC20 collateral and borrowed assets
interface IERC20 {
    function transfer(address to, uint256 amt) external returns (bool);
    function transferFrom(address fr, address to, uint256 amt) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

/// Interface for price oracles
interface IOracle {
    function getPrice() external view returns (uint256);
}

/// 1) Margin Short Position
contract MarginShort is Base, ReentrancyGuard {
    IERC20 public collateral;
    IERC20 public asset;
    IOracle public oracle;
    uint256 public minCollateralRatioBP;  // e.g. 15000 = 150%
    mapping(address => uint256) public collateralDeposited;
    mapping(address => uint256) public assetBorrowed;

    constructor(
        address _collateral,
        address _asset,
        address _oracle,
        uint256 _minCRBP
    ) {
        collateral = IERC20(_collateral);
        asset      = IERC20(_asset);
        oracle     = IOracle(_oracle);
        minCollateralRatioBP = _minCRBP;
    }

    // --- Attack: borrow without collateral checks & reentrancy
    function borrowInsecure(uint256 assetAmt) external {
        // no collateral check
        asset.transfer(msg.sender, assetAmt);
        assetBorrowed[msg.sender] += assetAmt;
    }

    // --- Defense: enforce collateral ratio + CEI + reentrancy guard
    function borrowSecure(uint256 assetAmt) external nonReentrant {
        // Effects: require collateral deposited and ratio
        uint256 colBal = collateral.balanceOf(msg.sender);
        uint256 price = oracle.getPrice();  // asset price in collateral units
        require(colBal > 0, "No collateral");
        // collateral value * 1e18 / price >= borrowed * ratioBP/10000
        require(
            colBal * 1e18 * 10000 / price
                >= (assetBorrowed[msg.sender] + assetAmt) * minCollateralRatioBP,
            "Under-collateralized"
        );
        assetBorrowed[msg.sender] += assetAmt;
        // Interaction
        asset.transfer(msg.sender, assetAmt);
    }

    // deposit collateral
    function depositCollateral(uint256 amt) external {
        collateral.transferFrom(msg.sender, address(this), amt);
        collateralDeposited[msg.sender] += amt;
    }
}

/// 2) Synthetic Short via Tokenized Swap
contract SyntheticShort is Base, ReentrancyGuard {
    IERC20 public collateral;
    IERC20 public synth;        // inverse token
    IOracle public oracle;
    uint256 public maxMint;     // cap on total mint
    uint256 public totalMinted;
    mapping(address => uint256) public minted;

    constructor(
        address _collateral,
        address _synth,
        address _oracle,
        uint256 _maxMint
    ) {
        collateral = IERC20(_collateral);
        synth      = IERC20(_synth);
        oracle     = IOracle(_oracle);
        maxMint    = _maxMint;
    }

    // --- Attack: mint unlimited synth with no collateral or cap
    function mintInsecure(uint256 amt) external {
        synth.transfer(msg.sender, amt);
        minted[msg.sender] += amt;
        totalMinted += amt;
    }

    // --- Defense: require deposit, cap, oracle sanity
    function mintSecure(uint256 amt) external nonReentrant {
        require(totalMinted + amt <= maxMint, "Cap exceeded");
        // require collateral deposit equal to price * amt
        uint256 price = oracle.getPrice();  // collateral per unit
        uint256 required = amt * price / 1e18;
        collateral.transferFrom(msg.sender, address(this), required);
        minted[msg.sender]   += amt;
        totalMinted          += amt;
        synth.transfer(msg.sender, amt);
    }

    // redeem synth back into collateral
    function redeemSecure(uint256 amt) external nonReentrant {
        require(minted[msg.sender] >= amt, "Not minted");
        uint256 price = oracle.getPrice();
        uint256 ret = amt * price / 1e18;
        minted[msg.sender]  -= amt;
        totalMinted         -= amt;
        synth.transferFrom(msg.sender, address(this), amt);
        collateral.transfer(msg.sender, ret);
    }
}

/// 3) Perpetual Protocol Short
contract PerpShort is Base, ReentrancyGuard {
    IERC20 public collateral;
    IOracle public fundingOracle;
    uint256 public maxPositionSize;
    uint256 public maxFundingShiftBP;  // e.g. 500 = 5%

    struct Position { int256 size; uint256 entryPrice; }
    mapping(address => Position) public positions;

    constructor(
        address _collateral,
        address _fundingOracle,
        uint256 _maxSize,
        uint256 _maxShiftBP
    ) {
        collateral         = IERC20(_collateral);
        fundingOracle      = IOracle(_fundingOracle);
        maxPositionSize    = _maxSize;
        maxFundingShiftBP  = _maxShiftBP;
    }

    // --- Attack: open unlimited short, no funding checks
    function openShortInsecure(int256 size) external {
        positions[msg.sender].size -= size;
    }

    // --- Defense: enforce size limit + CEI + reentrancy
    function openShortSecure(int256 size) external nonReentrant {
        require(size > 0, "Size>0");
        int256 newSize = positions[msg.sender].size - size;
        require(uint256(-newSize) <= maxPositionSize, "Position too large");
        positions[msg.sender].size = newSize;
        positions[msg.sender].entryPrice = fundingOracle.getPrice();
    }

    // funding payment settlement (attack: extreme rate)
    function settleFundingInsecure() external {
        // naive: read oracle and apply full shift
        uint256 rate = fundingOracle.getPrice();
        positions[msg.sender].entryPrice = rate;
    }

    // defense: cap per-interval funding shift
    function settleFundingSecure() external nonReentrant {
        uint256 current = fundingOracle.getPrice();
        uint256 prev    = positions[msg.sender].entryPrice;
        if (current > prev) {
            uint256 shift = (current - prev) * 10000 / prev;
            require(shift <= maxFundingShiftBP, "Funding shift too high");
        } else {
            uint256 shift = (prev - current) * 10000 / prev;
            require(shift <= maxFundingShiftBP, "Funding shift too high");
        }
        positions[msg.sender].entryPrice = current;
    }
}
