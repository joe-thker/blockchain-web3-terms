// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title StackingSatsSuite
/// @notice Modules: SimpleVault, DCAScheduler, TimeLockStake

interface ITwapOracle {
    /// @return price of ETH in sats (1e8)
    function twap() external view returns (uint256);
}

interface ISatsToken {
    function mint(address to, uint256 sats) external;
    function burn(address from, uint256 sats) external;
}

//////////////////////////////////////////
// 1) Simple Sats Vault
//////////////////////////////////////////
contract SimpleVault is ReentrancyGuard {
    ITwapOracle public oracle;
    ISatsToken  public satsToken;
    uint256     public maxSlippageBP = 500; // 5%

    constructor(ITwapOracle _oracle, ISatsToken _satsToken) {
        oracle    = _oracle;
        satsToken = _satsToken;
    }

    // --- Attack: no price check, reentrant mint
    function mintInsecure(uint256 minPrice) external payable {
        // uses msg.value * stale price ⇒ user can manipulate or reenter
        uint256 price = oracle.twap();
        require(price >= minPrice, "Price too low");
        uint256 sats = msg.value * price;
        satsToken.mint(msg.sender, sats);
    }

    // --- Defense: verify TWAP within slippage & nonReentrant
    function mintSecure(uint256 minPrice) external nonReentrant payable {
        uint256 price = oracle.twap();
        // enforce slippage bound
        require(price >= minPrice, "TWAP below minPrice");
        // compute sats to mint
        uint256 sats = msg.value * price;
        satsToken.mint(msg.sender, sats);
    }
}

//////////////////////////////////////////
// 2) DCA Scheduler
//////////////////////////////////////////
contract DCAScheduler {
    ISatsToken public satsToken;
    uint256    public interval;    // e.g. seconds between buys
    uint256    public nextRun;
    uint256    public maxRunsPerCall = 10;
    address    public owner;

    event DCARun(uint256 runs, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(ISatsToken _satsToken, uint256 _interval) {
        satsToken = _satsToken;
        interval   = _interval;
        nextRun    = block.timestamp + interval;
        owner      = msg.sender;
    }

    // --- Attack: anyone or too frequent runs
    function runInsecure() external {
        // runs as many times as possible, no schedule
        uint256 runs;
        while (runs < 1000) {  // potential DoS
            satsToken.mint(owner, 1e8);
            runs++;
        }
        emit DCARun(runs, block.timestamp);
    }

    // --- Defense: onlyOwner, schedule, limit iterations
    function runSecure() external onlyOwner {
        require(block.timestamp >= nextRun, "Too early");
        uint256 runs = (block.timestamp - nextRun) / interval + 1;
        if (runs > maxRunsPerCall) runs = maxRunsPerCall;
        for (uint256 i = 0; i < runs; i++) {
            satsToken.mint(owner, 1e8);  // mint 1 sats unit
            nextRun += interval;
        }
        emit DCARun(runs, block.timestamp);
    }
}

//////////////////////////////////////////
// 3) Time-Locked Sats Stake
//////////////////////////////////////////
contract TimeLockStake is ReentrancyGuard {
    ISatsToken public satsToken;

    struct Lock { uint256 amount; uint256 unlockTime; }
    mapping(address => Lock) public locks;

    event Locked(address indexed user, uint256 amount, uint256 until);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(ISatsToken _satsToken) {
        satsToken = _satsToken;
    }

    // --- Attack: instantly withdraw or owner drain
    function lockInsecure(uint256 sats, uint256 duration) external {
        // no real lock; owner could misuse mapping
        locks[msg.sender] = Lock(sats, block.timestamp + duration);
        satsToken.burn(msg.sender, sats);
    }
    function withdrawInsecure() external {
        Lock storage l = locks[msg.sender];
        satsToken.mint(msg.sender, l.amount);
        delete locks[msg.sender];
        emit Withdrawn(msg.sender, l.amount);
    }

    // --- Defense: enforce unlockTime + user-only withdraw
    function lockSecure(uint256 sats, uint256 duration) external nonReentrant {
        require(locks[msg.sender].amount == 0, "Existing lock");
        uint256 until = block.timestamp + duration;
        locks[msg.sender] = Lock(sats, until);
        satsToken.burn(msg.sender, sats);
        emit Locked(msg.sender, sats, until);
    }
    function withdrawSecure() external nonReentrant {
        Lock storage l = locks[msg.sender];
        require(l.amount > 0, "No stake");
        require(block.timestamp >= l.unlockTime, "Locked");
        uint256 amt = l.amount;
        delete locks[msg.sender];
        satsToken.mint(msg.sender, amt);
        emit Withdrawn(msg.sender, amt);
    }
}
