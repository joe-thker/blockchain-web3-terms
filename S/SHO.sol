// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SHO (Strong Holder Offering) Suite
/// @notice Implements Eligibility, TokenSale, and Vesting contracts
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Basic reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// 1) Holder Eligibility Verification
contract SHOEligibility is Base {
    IERC20  public stakeToken;
    uint256 public threshold;           // minimum tokens to qualify
    uint256 public snapshotBlock;       // block number for balance check

    mapping(address => bool) public registered;
    address[] public registrants;

    constructor(address _stakeToken, uint256 _threshold) {
        stakeToken = IERC20(_stakeToken);
        threshold  = _threshold;
    }

    // --- Attack: no snapshot, flash-loans can spoof balance
    function registerInsecure() external {
        require(stakeToken.balanceOf(msg.sender) >= threshold, "Insufficient stake");
        registrants.push(msg.sender);
        registered[msg.sender] = true;
    }

    // --- Defense: set snapshot then require snapshot‐balance + one‐time
    function setSnapshot(uint256 blockNum) external onlyOwner {
        snapshotBlock = blockNum;
    }
    function registerSecure() external {
        require(!registered[msg.sender], "Already registered");
        // use historical balanceAt if token supports snapshots,
        // here we approximate by requiring block.number == snapshot
        require(block.number > snapshotBlock, "Snapshot not reached");
        require(_balanceAt(msg.sender, snapshotBlock) >= threshold, "Insufficient stake at snapshot");
        registrants.push(msg.sender);
        registered[msg.sender] = true;
    }

    // stub: for real snapshot ERC20, call balanceOfAt; fallback to current
    function _balanceAt(address user, uint256) internal view returns (uint256) {
        return stakeToken.balanceOf(user);
    }
}

/// ERC20 interface
interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address,uint256) external returns (bool);
}

/// 2) Token Purchase Mechanism
contract SHOTokenSale is Base, ReentrancyGuard {
    IERC20  public shoeToken;
    uint256 public priceWei;            // wei per token
    uint256 public cap;                 // total tokens for sale
    uint256 public perUserCap;          // max per address

    mapping(address => uint256) public purchased;

    constructor(address _shoeToken, uint256 _price, uint256 _cap, uint256 _perUserCap) {
        shoeToken   = IERC20(_shoeToken);
        priceWei    = _price;
        cap         = _cap;
        perUserCap  = _perUserCap;
    }

    // --- Attack: reentrant buy or no cap checks
    function buyInsecure(uint256 amount) external payable {
        require(msg.value == amount * priceWei, "Wrong ETH");
        // no global or per-user cap
        shoeToken.transfer(msg.sender, amount);
    }

    // --- Defense: CEI + reentrancy guard + cap enforcement
    function buySecure(uint256 amount) external payable nonReentrant {
        require(msg.value == amount * priceWei, "Wrong ETH");
        require(purchased[msg.sender] + amount <= perUserCap, "Exceeds per-user cap");
        require(amount + _totalSold() <= cap,              "Exceeds total cap");
        purchased[msg.sender] += amount;
        shoeToken.transfer(msg.sender, amount);
    }

    // stub: track total sold via purchases mapping
    function _totalSold() internal view returns (uint256 total) {
        // in practice, sum all registrants or maintain a counter
        // here omitted for brevity
        return 0;
    }

    // allow owner to withdraw collected ETH
    function withdrawETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}

/// 3) Vesting & Cliff Release
contract SHOVesting is Base, ReentrancyGuard {
    IERC20  public shoeToken;
    uint256 public cliffTime;           // timestamp when vesting starts
    uint256 public vestDuration;        // total vesting duration

    struct Grant { uint256 total; uint256 released; }
    mapping(address => Grant) public grants;

    constructor(address _shoeToken, uint256 _cliff, uint256 _duration) {
        require(_cliff < block.timestamp + 365 days, "Bad cliff");
        require(_duration > 0,              "Good duration");
        shoeToken    = IERC20(_shoeToken);
        cliffTime    = _cliff;
        vestDuration = _duration;
    }

    // --- Attack: bypass cliff and withdraw immediately
    function releaseInsecure() external {
        Grant storage g = grants[msg.sender];
        // no time checks
        uint256 amt = g.total;
        g.released = amt;
        shoeToken.transfer(msg.sender, amt);
    }

    // --- Defense: enforce cliff + linear vesting + CEI
    function releaseSecure() external nonReentrant {
        Grant storage g = grants[msg.sender];
        require(block.timestamp >= cliffTime, "Vesting not started");
        uint256 elapsed = block.timestamp - cliffTime;
        uint256 vested = g.total * (elapsed < vestDuration ? elapsed : vestDuration) / vestDuration;
        uint256 releasable = vested - g.released;
        require(releasable > 0, "Nothing to release");
        g.released += releasable;
        shoeToken.transfer(msg.sender, releasable);
    }

    // owner assigns grants to registered holders
    function grantTokens(address to, uint256 amount) external onlyOwner {
        grants[to].total += amount;
    }
}
