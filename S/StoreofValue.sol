// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// ------------------------------------------------------------------------
/// 1) Fixed-Supply Token
/// ------------------------------------------------------------------------
contract FixedSupplyToken {
    string public name = "ValueToken";
    string public symbol = "VT";
    uint8  public decimals = 18;
    uint256 public cap;                // immutable max supply
    uint256 public totalSupply;
    uint256 public perMintLimit;       // max per mint

    address public owner;
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    constructor(uint256 _cap, uint256 _perMintLimit) {
        cap = _cap;
        perMintLimit = _perMintLimit;
        owner = msg.sender;
    }

    mapping(address=>uint256) public balanceOf;

    // --- Attack: anyone can mint any amount ⇒ unlimited inflation
    function mintInsecure(address to, uint256 amt) external {
        // no owner check, no cap
        balanceOf[to] += amt;
        totalSupply   += amt;
    }

    // --- Defense: onlyOwner + enforce cap and per-mint limit
    function mintSecure(address to, uint256 amt) external onlyOwner {
        require(amt <= perMintLimit, "Mint exceeds perMintLimit");
        require(totalSupply + amt <= cap, "Cap exceeded");
        balanceOf[to] += amt;
        totalSupply   += amt;
    }
}

/// ------------------------------------------------------------------------
/// 2) Collateral-Backed Vault
/// ------------------------------------------------------------------------
interface ITWAP { function getTwapPrice() external view returns (uint256); }

contract CollateralVault is ReentrancyGuard {
    IERC20  public collateral;          // e.g. USDC
    IERC20  public shareToken;          // vault receipt
    ITWAP[] public oracles;             // price feeds
    uint256 public staleAfter = 300;    // seconds
    uint256 public collateralRatioBP;   // e.g. 15000 = 150%

    mapping(address=>uint256) public shares;

    constructor(
        IERC20 _collateral,
        IERC20 _shareToken,
        ITWAP[] memory _oracles,
        uint256 _ratioBP
    ) {
        collateral      = _collateral;
        shareToken      = _shareToken;
        oracles         = _oracles;
        collateralRatioBP = _ratioBP;
    }

    // --- Attack: withdraw even if under-collateralized
    function withdrawInsecure(uint256 shareAmt) external {
        // no collateral check, no oracle
        shares[msg.sender] -= shareAmt;
        collateral.transfer(msg.sender, shareAmt);
    }

    // --- Defense: enforce over-collateralization via TWAP
    function withdrawSecure(uint256 shareAmt) external nonReentrant {
        require(shares[msg.sender] >= shareAmt, "Insufficient shares");
        // compute vault value
        uint256 price = _twap();
        // collateral needed = shareAmt * price * ratioBP / 1e18 / 10000
        uint256 needed = shareAmt * price * collateralRatioBP / 1e18 / 10000;
        uint256 vaultBal = collateral.balanceOf(address(this));
        require(vaultBal >= needed, "Under-collateralized");
        // Effects
        shares[msg.sender] -= shareAmt;
        // Interaction
        collateral.transfer(msg.sender, shareAmt);
    }

    function deposit(uint256 amt) external {
        collateral.transferFrom(msg.sender, address(this), amt);
        shares[msg.sender] += amt;
    }

    function _twap() internal view returns (uint256) {
        uint256 sum;
        for (uint i=0; i<oracles.length; i++){
            (uint256 p)= oracles[i].getTwapPrice();
            sum += p;
        }
        return sum / oracles.length;
    }
}

/// ------------------------------------------------------------------------
/// 3) Time-Locked Savings
/// ------------------------------------------------------------------------
contract TimeLockSavings is ReentrancyGuard {
    IERC20 public token;
    uint256 public minLock;   // minimal lock duration

    struct Lock { uint256 amount; uint256 unlockTime; }
    mapping(address=>Lock) public locks;

    constructor(IERC20 _token, uint256 _minLock) {
        token   = _token;
        minLock = _minLock;
    }

    // --- Attack: instant lock + withdraw, no real time constraint
    function lockInsecure(uint256 amt) external {
        token.transferFrom(msg.sender, address(this), amt);
        locks[msg.sender] = Lock(amt, 0);
    }
    function withdrawInsecure() external {
        Lock storage l = locks[msg.sender];
        // no time check
        token.transfer(msg.sender, l.amount);
        l.amount = 0;
    }

    // --- Defense: enforce time-lock + prevent reentrancy
    function lockSecure(uint256 amt, uint256 duration) external nonReentrant {
        require(duration >= minLock, "Lock too short");
        token.transferFrom(msg.sender, address(this), amt);
        locks[msg.sender] = Lock(amt, block.timestamp + duration);
    }
    function withdrawSecure() external nonReentrant {
        Lock storage l = locks[msg.sender];
        require(l.amount > 0, "No lock");
        require(block.timestamp >= l.unlockTime, "Locked");
        uint256 amt = l.amount;
        l.amount = 0;
        token.transfer(msg.sender, amt);
    }
}
