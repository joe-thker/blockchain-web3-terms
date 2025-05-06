// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Base {
    address public owner;
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
    constructor() { owner = msg.sender; }
}

abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() { require(!_locked, "Reentrant"); _locked = true; _; _locked = false; }
}

/// Simplified Oracle Interface
interface IOracle {
    function getPrice() external view returns (uint256); // returns price with 1e18 precision
}

/// ---------------------------------------------------------
/// 1) Oracle Price Band Peg
/// ---------------------------------------------------------
contract PegOracleBand is Base {
    IOracle[] public oracles;
    uint256 public bandBP;          // allowed deviation in basis points
    address public keeper;
    uint256 public lastAdjust;      // timestamp of last peg adjust
    uint256 public adjustCooldown;  // e.g. 1 hour
    uint256 public maxAdjustBP;     // max percent of supply to mint/burn per adjust

    modifier onlyKeeper() { require(msg.sender == keeper, "Not keeper"); _; }

    constructor(IOracle[] memory _oracles, uint256 _bandBP, uint256 _cooldown, uint256 _maxBP) {
        oracles = _oracles;
        bandBP = _bandBP;
        adjustCooldown = _cooldown;
        maxAdjustBP = _maxBP;
        keeper = msg.sender;
    }

    // --- Attack: anyone can call, single oracle, no bounds
    function adjustInsecure() external {
        uint256 p = oracles[0].getPrice(); // single oracle
        // blindly mint/burn equal to deviation
        // ...
    }

    // --- Defense: multi‐oracle TWAP + access + cooldown + capped
    function adjustSecure() external onlyKeeper {
        require(block.timestamp >= lastAdjust + adjustCooldown, "Cooldown");
        uint256 sum;
        for (uint i; i<oracles.length; i++) {
            sum += oracles[i].getPrice();
        }
        uint256 avg = sum / oracles.length;
        uint256 target = 1e18;
        uint256 diff = avg > target ? avg - target : target - avg;
        require(diff * 10000 / target > bandBP, "Within band");

        // compute adjustment capped by maxAdjustBP
        uint256 supply = address(this).balance; // placeholder for total supply
        uint256 adjustAmt = supply * diff / target;
        uint256 capAmt = supply * maxAdjustBP / 10000;
        if (adjustAmt > capAmt) adjustAmt = capAmt;
        // mint or burn adjustAmt...
        lastAdjust = block.timestamp;
    }
}

/// ---------------------------------------------------------
/// 2) AMM Rebalancing Pool
/// ---------------------------------------------------------
interface IPair {
    function getReserves() external view returns (uint112 r0, uint112 r1, uint32);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata) external;
    function sync() external;
}

contract PegAMMRebalance is Base, ReentrancyGuard {
    IPair public pair;
    uint256 public targetPrice;  // 1e18 = peg price of token0/token1
    uint256 public feeBP;        // basis points fee on rebalance
    uint256 public minFeeBP;     // minimum floor fee
    address public token0;
    address public token1;

    constructor(IPair _pair, uint256 _target, uint256 _fee, uint256 _minFee, address _t0, address _t1) {
        pair = _pair;
        targetPrice = _target;
        feeBP = _fee;
        minFeeBP = _minFee;
        token0 = _t0; token1 = _t1;
    }

    // --- Attack: no fee, can front‐run, drain reserves
    function rebalanceInsecure() external {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 price = uint256(r1)*1e18/r0;
        // calculate swap amounts and call swap...
    }

    // --- Defense: fee & CEI & nonReentrant
    function rebalanceSecure() external nonReentrant {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 price = uint256(r1)*1e18/r0;
        if (price > targetPrice) {
            // too high: sell token1 for token0
            uint256 deviation = price - targetPrice;
            uint256 amt1 = uint256(r1) * deviation / price;
            uint256 fee = amt1 * feeBP / 10000;
            if (fee < amt1 * minFeeBP / 10000) fee = amt1 * minFeeBP / 10000;
            uint256 out0 = (amt1 - fee) * r0 / r1;
            // CEI: transfer amt1 from caller into pair, then swap
            // ...
        } else if (price < targetPrice) {
            // mirror for token0 → token1
            // ...
        }
        pair.sync();
    }
}

/// ---------------------------------------------------------
/// 3) Collateral-Backed Mint/Burn Peg
/// ---------------------------------------------------------
contract PegCollateral is Base, ReentrancyGuard {
    IOracle public oracle;
    uint256 public collateralRatioBP; // e.g. 150% = 15000
    mapping(address=>uint256) public collateral;  // user collateral
    mapping(address=>uint256) public debt;        // user debt

    constructor(IOracle _oracle, uint256 _ratioBP) {
        oracle = _oracle;
        collateralRatioBP = _ratioBP;
    }

    // --- Attack: mint without sufficient collateral, stale oracle
    function mintInsecure(uint256 amount) external payable {
        debt[msg.sender] += amount;
        // mint amount...
    }

    // --- Defense: enforce collateral ratio + TWAP oracle + auto‐liquidation
    function mintSecure(uint256 amount) external payable nonReentrant {
        collateral[msg.sender] += msg.value;
        uint256 price = oracle.getPrice(); // assume TWAP
        uint256 needed = amount * price * collateralRatioBP / 1e18 / 10000;
        require(collateral[msg.sender] >= needed, "Undercollateralized");
        debt[msg.sender] += amount;
        // mint amount...
    }

    function burnSecure(uint256 amount) external nonReentrant {
        debt[msg.sender] -= amount;
        // burn amount...
    }

    // simple liquidate undercollateralized positions
    function liquidate(address user) external nonReentrant {
        uint256 price = oracle.getPrice();
        uint256 col = collateral[user];
        uint256 req = debt[user] * price * collateralRatioBP / 1e18 / 10000;
        require(col < req, "Healthy");
        // seize collateral, burn debt...
        collateral[user] = 0;
        debt[user] = 0;
    }
}
