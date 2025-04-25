// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title PerpetualContractsSuite.sol
/// @notice On‐chain analogues of “Perpetual Contracts” trading patterns:
///   Types: Linear, Inverse, Quanto, Spread  
///   AttackTypes: OracleManipulation, PriceDrift, LiquidationAttack, FrontRunning  
///   DefenseTypes: AccessControl, OracleValidation, FundingRateAdjust, RateLimit, SignatureValidation

enum PerpType               { Linear, Inverse, Quanto, Spread }
enum PerpAttackType         { OracleManipulation, PriceDrift, LiquidationAttack, FrontRunning }
enum PerpDefenseType        { AccessControl, OracleValidation, FundingRateAdjust, RateLimit, SignatureValidation }

error PC__NotOwner();
error PC__InvalidPrice();
error PC__TooManyRequests();
error PC__InvalidSignature();

////////////////////////////////////////////////////////////////////////////////
// 1) VULNERABLE PERPETUAL CONTRACT
//    • ❌ anyone sets price and trades → OracleManipulation
////////////////////////////////////////////////////////////////////////////////
contract PerpVuln {
    mapping(PerpType => uint256) public price;
    mapping(address => int256)  public positions;

    event PriceUpdated(
        address indexed who,
        PerpType        ptype,
        uint256         newPrice,
        PerpAttackType  attack
    );
    event Trade(
        address indexed who,
        PerpType        ptype,
        int256          qty,
        uint256         executionPrice,
        PerpAttackType  attack
    );

    function updatePrice(PerpType ptype, uint256 newPrice) external {
        price[ptype] = newPrice;
        emit PriceUpdated(msg.sender, ptype, newPrice, PerpAttackType.OracleManipulation);
    }

    function trade(PerpType ptype, int256 qty) external {
        uint256 exec = price[ptype];
        positions[msg.sender] += qty;
        emit Trade(msg.sender, ptype, qty, exec, PerpAttackType.PriceDrift);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 2) ATTACK STUB
//    • simulates oracle manipulation, mass liquidation, frontrunning
////////////////////////////////////////////////////////////////////////////////
contract Attack_Perps {
    PerpVuln public target;
    PerpType public lastType;
    uint256  public lastPrice;
    int256   public lastQty;

    constructor(PerpVuln _t) {
        target = _t;
    }

    function manipulateOracle(PerpType ptype, uint256 fakePrice) external {
        target.updatePrice(ptype, fakePrice);
        lastType = ptype;
        lastPrice = fakePrice;
    }

    function massLiquidate(PerpType ptype, int256 qty, uint count) external {
        for (uint i = 0; i < count; i++) {
            target.trade(ptype, qty);
        }
    }

    function frontRunTrade(PerpType ptype, int256 qty) external {
        target.trade(ptype, qty);
        lastQty = qty;
        lastType = ptype;
    }

    function replay() external {
        target.updatePrice(lastType, lastPrice);
        target.trade(lastType, lastQty);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 3) SAFE WITH ACCESS CONTROL
//    • ✅ Defense: AccessControl – only owner may update price
////////////////////////////////////////////////////////////////////////////////
contract PerpSafeAccess {
    mapping(PerpType => uint256) public price;
    mapping(address => int256)  public positions;
    address public owner;

    event PriceUpdated(
        address indexed who,
        PerpType        ptype,
        uint256         newPrice,
        PerpDefenseType defense
    );
    event Trade(
        address indexed who,
        PerpType        ptype,
        int256          qty,
        uint256         executionPrice,
        PerpDefenseType defense
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert PC__NotOwner();
        _;
    }

    function updatePrice(PerpType ptype, uint256 newPrice) external onlyOwner {
        price[ptype] = newPrice;
        emit PriceUpdated(msg.sender, ptype, newPrice, PerpDefenseType.AccessControl);
    }

    function trade(PerpType ptype, int256 qty) external {
        uint256 exec = price[ptype];
        positions[msg.sender] += qty;
        emit Trade(msg.sender, ptype, qty, exec, PerpDefenseType.AccessControl);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 4) SAFE WITH ORACLE VALIDATION & RATE LIMIT
//    • ✅ Defense: OracleValidation – require signed price  
//               RateLimit         – cap updates per block
////////////////////////////////////////////////////////////////////////////////
contract PerpSafeOracle {
    mapping(PerpType => uint256) public price;
    mapping(address => int256)  public positions;
    mapping(address => uint256) public lastBlock;
    mapping(address => uint256) public updatesInBlock;
    uint256 public constant MAX_UPDATES = 3;
    address public oracleSigner;

    event PriceUpdated(
        address indexed who,
        PerpType        ptype,
        uint256         newPrice,
        PerpDefenseType defense
    );
    event Trade(
        address indexed who,
        PerpType        ptype,
        int256          qty,
        uint256         executionPrice,
        PerpDefenseType defense
    );

    constructor(address _oracleSigner) {
        oracleSigner = _oracleSigner;
    }

    error PC__TooManyRequests();
    error PC__InvalidSignature();

    function updatePrice(
        PerpType ptype,
        uint256 newPrice,
        bytes calldata sig
    ) external {
        // rate-limit
        if (block.number != lastBlock[msg.sender]) {
            lastBlock[msg.sender]    = block.number;
            updatesInBlock[msg.sender] = 0;
        }
        updatesInBlock[msg.sender]++;
        if (updatesInBlock[msg.sender] > MAX_UPDATES) revert PC__TooManyRequests();

        // verify oracle signature over (ptype||newPrice)
        bytes32 h = keccak256(abi.encodePacked(ptype, newPrice));
        bytes32 eth = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(sig,(uint8,bytes32,bytes32));
        if (ecrecover(eth, v, r, s) != oracleSigner) revert PC__InvalidSignature();

        price[ptype] = newPrice;
        emit PriceUpdated(msg.sender, ptype, newPrice, PerpDefenseType.OracleValidation);
    }

    function trade(PerpType ptype, int256 qty) external {
        uint256 exec = price[ptype];
        positions[msg.sender] += qty;
        emit Trade(msg.sender, ptype, qty, exec, PerpDefenseType.OracleValidation);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 5) SAFE ADVANCED WITH FUNDING RATE ADJUST & SIGNATURE VALIDATION
//    • ✅ Defense: FundingRateAdjust    – periodic funding update stub  
//               SignatureValidation   – require admin signature on trade
////////////////////////////////////////////////////////////////////////////////
contract PerpSafeAdvanced {
    mapping(PerpType => uint256) public price;
    mapping(PerpType => int256)  public fundingRate;
    mapping(address => int256)   public positions;
    address public signer;

    event FundingUpdated(
        PerpType        ptype,
        int256          newRate,
        PerpDefenseType defense
    );
    event Trade(
        address indexed who,
        PerpType        ptype,
        int256          qty,
        uint256         executionPrice,
        PerpDefenseType defense
    );

    error PC__InvalidSignature();

    constructor(address _signer) {
        signer = _signer;
    }

    function updateFundingRate(PerpType ptype, int256 newRate) external {
        // stub: only protocol can call
        fundingRate[ptype] = newRate;
        emit FundingUpdated(ptype, newRate, PerpDefenseType.FundingRateAdjust);
    }

    function trade(
        PerpType ptype,
        int256 qty,
        bytes calldata sig
    ) external {
        // verify signature over (msg.sender||ptype||qty)
        bytes32 h = keccak256(abi.encodePacked(msg.sender, ptype, qty));
        bytes32 eth = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(sig,(uint8,bytes32,bytes32));
        if (ecrecover(eth, v, r, s) != signer) revert PC__InvalidSignature();

        uint256 exec = price[ptype];
        positions[msg.sender] += qty;
        emit Trade(msg.sender, ptype, qty, exec, PerpDefenseType.SignatureValidation);
    }
}
