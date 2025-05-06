// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
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

// Simplified ERC20 / pool interfaces
interface IERC20 {
    function balanceOf(address) external view returns(uint);
    function transfer(address,uint) external returns(bool);
    function transferFrom(address,address,uint) external returns(bool);
}
interface IBalancerPool {
    function joinPool(uint, uint[], uint) external;
    function exitPool(uint, uint[], uint) external;
}

//////////////////////////////////////////////////////
// 1) Pool Liquidity Management
//////////////////////////////////////////////////////
contract TreasuryLiquidity is Base, ReentrancyGuard {
    IBalancerPool public pool;
    IERC20[]      public tokens;
    uint[]        public weights;       // for reference
    uint          public slippageBound; // e.g. 5%

    constructor(address _pool, IERC20[] memory _tokens, uint[] memory _weights, uint _slipBP) {
        pool        = IBalancerPool(_pool);
        tokens      = _tokens;
        weights     = _weights;
        slippageBound = _slipBP;
    }

    // --- Attack: exit with no minAmounts ⇒ full drain
    function removeLiquidityInsecure(uint poolAmount, uint[] calldata /*minAmountsOut*/) external {
        // no bounds check
        pool.exitPool(poolAmount, new uint[](tokens.length),  type(uint).max);
    }

    // --- Defense: require minAmountsOut + CEI + nonReentrant
    function removeLiquiditySecure(
        uint poolAmount,
        uint[] calldata minAmountsOut
    ) external nonReentrant onlyOwner {
        require(minAmountsOut.length == tokens.length, "Bad length");
        // compute bounds based on slippageBound
        uint[] memory bounds = new uint[](tokens.length);
        for(uint i; i<tokens.length; i++){
            uint bal = tokens[i].balanceOf(address(pool));
            uint expected = (bal * poolAmount) / poolAmount; // simplified
            bounds[i] = expected * (10000 - slippageBound) / 10000;
            require(minAmountsOut[i] >= bounds[i], "Slippage too high");
        }
        pool.exitPool(poolAmount, minAmountsOut, poolAmount);
    }

    // (Similar addLiquidityInsecure vs. addLiquiditySecure omitted for brevity)
}

//////////////////////////////////////////////////////
// 2) Treasury Asset Rebalancing
//////////////////////////////////////////////////////
contract TreasuryRebalance is Base, ReentrancyGuard {
    uint    public lastRebalance;
    uint    public cooldown;   // e.g. 1 day
    uint    public maxPct;     // max percent per rebalance, in BP
    IERC20  public tokenA;
    IERC20  public tokenB;
    // Dummy DEX interface
    function swap(address from, address to, uint amt) internal returns(uint) { return amt; }

    constructor(IERC20 _a, IERC20 _b, uint _cd, uint _maxBP) {
        tokenA    = _a;
        tokenB    = _b;
        cooldown  = _cd;
        maxPct    = _maxBP;
    }

    // --- Attack: anyone triggers frequent rebalances, large swaps
    function rebalanceInsecure(uint amtAtoB) external {
        swap(address(tokenA), address(tokenB), amtAtoB);
    }

    // --- Defense: onlyOwner, cooldown, maxPct, CEI + nonReentrant
    function rebalanceSecure(uint amtAtoB) external onlyOwner nonReentrant {
        require(block.timestamp >= lastRebalance + cooldown, "Cooldown");
        uint balA = tokenA.balanceOf(address(this));
        require(amtAtoB <= balA * maxPct / 10000, "Amt too large");
        lastRebalance = block.timestamp;
        swap(address(tokenA), address(tokenB), amtAtoB);
    }
}

//////////////////////////////////////////////////////
// 3) Yield Strategy Execution
//////////////////////////////////////////////////////
contract TreasuryStrategy is Base, ReentrancyGuard {
    address public strategy;
    uint    public lastHarvest;
    uint    public harvestCooldown;
    uint    public minHarvestAmt; // threshold

    IERC20  public rewardToken;

    event StrategyUpdated(address old, address neu);
    event Harvested(address by, uint amount);

    constructor(address _strat, IERC20 _reward, uint _hc, uint _min) {
        strategy        = _strat;
        rewardToken     = _reward;
        harvestCooldown = _hc;
        minHarvestAmt   = _min;
    }

    // --- Attack: attacker points strategy to malicious, harvest endless
    function updateStrategyInsecure(address neu) external {
        strategy = neu;
    }

    // --- Defense: onlyOwner + timelock (omitted) + CEI
    function updateStrategySecure(address neu) external onlyOwner {
        // could require time‐locked commit; simplified here
        emit StrategyUpdated(strategy, neu);
        strategy = neu;
    }

    // --- Attack: harvest anytime, no min check
    function harvestInsecure() external {
        // assume strategy.harvest()
        uint amt = rewardToken.balanceOf(address(this));
        rewardToken.transfer(msg.sender, amt);
    }

    // --- Defense: cooldown + minAmt + nonReentrant
    function harvestSecure() external nonReentrant {
        require(block.timestamp >= lastHarvest + harvestCooldown, "Harvest cooldown");
        uint amt = rewardToken.balanceOf(address(this));
        require(amt >= minHarvestAmt, "Harvest amt too low");
        lastHarvest = block.timestamp;
        rewardToken.transfer(owner, amt);
        emit Harvested(msg.sender, amt);
    }
}
