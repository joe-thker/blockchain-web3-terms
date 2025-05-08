// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Simplified oracle interface returning value with 1e18 precision and timestamp
interface ITWAP {
    function getTwap() external view returns (uint256 value, uint256 updatedAt);
}

/// @title StockToFlowSuite
/// @notice 1) RatioCalc, 2) MintController, 3) SupplyAdjuster
contract StockToFlowSuite is ReentrancyGuard {
    ITWAP[] public stockOracles;
    ITWAP[] public flowOracles;
    uint256 public staleAfter = 1 hours;
    uint256 public epsilon     = 1; // tiny 1e-18 to avoid div0

    constructor(ITWAP[] memory _stock, ITWAP[] memory _flow) {
        stockOracles = _stock;
        flowOracles  = _flow;
    }

    /// ------------------------------------------------------------------------
    /// 1) On-Chain Ratio Calculation
    /// ------------------------------------------------------------------------
    // --- Attack: naive single-oracle, no div0 guard
    function ratioInsecure() external view returns (uint256) {
        (uint256 stock, ) = stockOracles[0].getTwap();
        (uint256 flow, )  = flowOracles[0].getTwap();
        // if flow==0, reverts or returns huge value
        return stock * 1e18 / flow;
    }

    // --- Defense: multi-oracle TWAP avg, freshness, div-zero guard
    function ratioSecure() public view returns (uint256) {
        uint256 sumStock; uint256 sumFlow;
        uint256 n = stockOracles.length;
        require(n == flowOracles.length && n > 0, "Mismatched oracles");
        for (uint i = 0; i < n; i++) {
            (uint256 s, uint256 t1) = stockOracles[i].getTwap();
            (uint256 f, uint256 t2) = flowOracles[i].getTwap();
            require(block.timestamp - t1 <= staleAfter &&
                    block.timestamp - t2 <= staleAfter,
                    "Oracle stale");
            sumStock += s;
            sumFlow  += f;
        }
        require(sumFlow > 0, "Zero flow");
        uint256 denom = sumFlow + epsilon;
        return sumStock * 1e18 / denom;
    }
}

/// @title MintController
/// @notice Adjusts mint rate based on S2F ratio
contract MintController is StockToFlowSuite {
    address public owner;
    uint256 public maxMintPerPeriod;
    uint256 public lastMint;
    uint256 public mintCooldown; // e.g. 1 day

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    constructor(ITWAP[] memory s, ITWAP[] memory f,
                uint256 _maxMint, uint256 _cooldown)
        StockToFlowSuite(s, f)
    {
        owner = msg.sender;
        maxMintPerPeriod = _maxMint;
        mintCooldown     = _cooldown;
    }

    // --- Attack: naive mint based on ratio, no caps or cooldown
    function mintInsecure(uint256 baseAmount) external {
        uint256 ratio = ratioInsecure();          // from parent
        uint256 toMint = baseAmount * 1e18 / ratio;
        // unlimited calls ⇒ huge mint if ratio small
        _mint(msg.sender, toMint);
    }

    // --- Defense: enforce onlyOwner, cooldown, and cap
    function mintSecure(uint256 baseAmount) external onlyOwner nonReentrant {
        require(block.timestamp >= lastMint + mintCooldown, "Cooldown");
        uint256 ratio = ratioSecure();
        uint256 toMint = baseAmount * 1e18 / ratio;
        require(toMint <= maxMintPerPeriod, "Mint cap exceeded");
        lastMint = block.timestamp;
        _mint(owner, toMint);
    }

    // placeholder mint function
    mapping(address => uint256) public balance;
    function _mint(address to, uint256 amt) internal {
        balance[to] += amt;
    }
}

/// @title SupplyAdjuster
/// @notice Rebalances supply target based on S2F bands
contract SupplyAdjuster is StockToFlowSuite {
    address public owner;
    uint256 public minSupply;
    uint256 public maxSupply;
    uint256 public lastAdjust;
    uint256 public adjustCooldown; // e.g. 1 day

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    constructor(ITWAP[] memory s, ITWAP[] memory f,
                uint256 _min, uint256 _max, uint256 _cooldown)
        StockToFlowSuite(s, f)
    {
        owner           = msg.sender;
        minSupply       = _min;
        maxSupply       = _max;
        adjustCooldown  = _cooldown;
        lastAdjust      = block.timestamp;
    }

    // --- Attack: immediate adjustment on every call ⇒ oscillation
    function adjustInsecure(uint256 currentSupply) external view returns (uint256) {
        uint256 ratio = ratioInsecure();
        // naive: newSupply = supply * ratio / 1e18
        return currentSupply * ratio / 1e18;
    }

    // --- Defense: TWMA of ratio, cooldown, supply bounds
    function adjustSecure(uint256 currentSupply) external onlyOwner nonReentrant returns (uint256) {
        require(block.timestamp >= lastAdjust + adjustCooldown, "Cooldown");
        uint256 ratio = ratioSecure();
        // compute new supply target
        uint256 target = currentSupply * ratio / 1e18;
        // clamp within bounds
        if (target < minSupply) target = minSupply;
        if (target > maxSupply) target = maxSupply;
        lastAdjust = block.timestamp;
        return target;
    }
}
