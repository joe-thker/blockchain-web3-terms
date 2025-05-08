// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title StablecoinSuite
/// @notice Modules: FiatCollateral, CryptoVault, RebaseToken

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// ------------------------------------------------------------------------
/// 1) Fiat-Collateralized Mint/Burn
/// ------------------------------------------------------------------------
contract FiatCollateral is ReentrancyGuard {
    IERC20 public collateral;     // e.g. USDC
    IERC20 public stable;         // this stablecoin
    uint256 public cap;           // max supply

    constructor(IERC20 _collateral, IERC20 _stable, uint256 _cap) {
        collateral = _collateral;
        stable     = _stable;
        cap        = _cap;
    }

    // --- Attack: mint without depositing collateral
    function mintInsecure(uint256 amount) external {
        // no collateral check
        // imagine stable.mint(...) here
        // omitted for brevity
    }

    // --- Defense: require collateral deposit & cap
    function mintSecure(uint256 amount) external nonReentrant {
        require(stable.totalSupply() + amount <= cap, "Cap exceeded");
        // pull collateral 1:1
        require(collateral.transferFrom(msg.sender, address(this), amount), "Collateral failed");
        // mint stable tokens to user
        // e.g. StableMintable(address(stable)).mint(msg.sender, amount);
    }

    // --- Attack: burn and immediately withdraw collateral, reentrancy
    function burnInsecure(uint256 amount) external {
        // e.g. stable.burnFrom(msg.sender, amount);
        collateral.transfer(msg.sender, amount);
    }

    // --- Defense: CEI + nonReentrant on burn
    function burnSecure(uint256 amount) external nonReentrant {
        // Effects: burn stable
        // e.g. StableMintable(address(stable)).burnFrom(msg.sender, amount);
        // Interaction: refund collateral
        require(collateral.transfer(msg.sender, amount), "Refund failed");
    }
}

/// ------------------------------------------------------------------------
/// 2) Crypto-Collateralized Vault (Over-Collateralized)
/// ------------------------------------------------------------------------
interface ITWAP { function getTwapPrice() external view returns (uint256); }

contract CryptoVault is ReentrancyGuard {
    IERC20 public collateralToken;   // e.g. ETH-wrapped
    IERC20 public stable;            // minted token
    ITWAP  public priceOracle;
    uint256 public imarginBP;        // initial margin e.g. 15000 = 150%
    uint256 public mmarginBP;        // maintenance margin e.g. 12500

    struct Vault { uint256 collateral; uint256 debt; }
    mapping(address=>Vault) public vaults;

    constructor(
        IERC20 _collateralToken,
        IERC20 _stable,
        ITWAP  _priceOracle,
        uint256 _im,
        uint256 _mm
    ) {
        collateralToken = _collateralToken;
        stable          = _stable;
        priceOracle     = _priceOracle;
        imarginBP       = _im;
        mmarginBP       = _mm;
    }

    // --- Attack: borrow unlimited with no margin checks
    function borrowInsecure(uint256 amount) external {
        vaults[msg.sender].debt += amount;
        // e.g. stable.mint(msg.sender, amount);
    }

    // --- Defense: enforce initial margin + CEI
    function borrowSecure(uint256 collateralAmt, uint256 amount) external nonReentrant {
        // pull collateral
        require(collateralToken.transferFrom(msg.sender, address(this), collateralAmt), "Coll fail");
        // check price
        uint256 price = priceOracle.getTwapPrice();
        uint256 collValue = collateralAmt * price / 1e18;
        require(collValue * 10000 >= amount * imarginBP, "Insufficient collateral");
        // Effects
        Vault storage v = vaults[msg.sender];
        v.collateral += collateralAmt;
        v.debt       += amount;
        // Interaction
        // e.g. StableMintable(address(stable)).mint(msg.sender, amount);
    }

    // Auto-liquidation if below maintenance
    function liquidate(address user) external nonReentrant {
        Vault storage v = vaults[user];
        uint256 price = priceOracle.getTwapPrice();
        uint256 collValue = v.collateral * price / 1e18;
        require(collValue * 10000 < v.debt * mmarginBP, "Vault healthy");
        // seize collateral
        uint256 seized = v.collateral;
        v.collateral = 0;
        v.debt       = 0;
        collateralToken.transfer(msg.sender, seized);
    }
}

/// ------------------------------------------------------------------------
/// 3) Algorithmic Rebase Token
/// ------------------------------------------------------------------------
abstract contract Rebaseable {
    function rebase(int256 supplyDelta) external virtual;
    function totalSupply() public view virtual returns (uint256);
}

contract RebaseToken is ReentrancyGuard, Rebaseable {
    string  public name = "RebaseUSD";
    uint8   public decimals = 18;
    uint256 public totalSupply;
    mapping(address=>uint256) public balanceOf;

    uint256 public lastRebase;
    uint256 public cooldown;      // e.g. 1 hour
    uint256 public minSupply;     // floor supply
    uint256 public maxSupply;     // cap supply

    constructor(
        uint256 _cooldown,
        uint256 _minSupply,
        uint256 _maxSupply
    ) {
        cooldown   = _cooldown;
        minSupply  = _minSupply;
        maxSupply  = _maxSupply;
    }

    // --- Attack: anyone calls rebase arbitrarily, profit via frontrun
    function rebaseInsecure(int256 supplyDelta) external {
        totalSupply = uint256(int256(totalSupply) + supplyDelta);
        // naive proportional adjust balances...
    }

    // --- Defense: onlyOwner + cooldown + bounds
    function rebase(int256 supplyDelta) external override nonReentrant {
        require(block.timestamp >= lastRebase + cooldown, "Cooldown");
        int256 newSupply = int256(totalSupply) + supplyDelta;
        require(newSupply >= int256(minSupply) && newSupply <= int256(maxSupply), "Out of bounds");
        totalSupply = uint256(newSupply);
        lastRebase  = block.timestamp;
        // proportional balance updates omitted for brevity
    }

    // ERC-20 transfers omitted for brevity…
}
