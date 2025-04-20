// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * OpenFi Lending Pool – single‑asset demo (DAI ↔ ETH)
 * ---------------------------------------------------
 * • Deposit DAI → receive oDAI receipt tokens (1 : 1).
 * • Borrow DAI against ETH collateral (60 % LTV).
 * • Flat per‑block interest; 110 % liquidation bonus.
 *
 * NOTE: The string literal “under‑collateral” contained a Unicode
 * en‑dash, causing `ParserError: Invalid character in string`.
 * It is now replaced with ASCII `"under-collateral"`.
 */
contract OpenFiLendingPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* ─── immutable config ─── */
    IERC20 public immutable DAI;
    uint16 public constant LTV_BP       = 6000;  // 60 %
    uint16 public constant LIQ_BONUS_BP = 11000; // 110 %
    uint256 public interestPerBlock;             // 1e18‑scaled

    /* ─── oDAI receipt “token” ─── */
    string  public constant name     = "OpenFi Deposit DAI";
    string  public constant symbol   = "oDAI";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    /* ─── user positions ─── */
    struct Account {
        uint256 deposit;    // DAI supplied
        uint256 debt;       // DAI owed
        uint256 collETH;    // wei collateral
        uint256 lastBlock;  // for interest accretion
    }
    mapping(address => Account) public accounts;

    /* ─── events ─── */
    event Deposit   (address indexed u, uint256 amt);
    event Withdraw  (address indexed u, uint256 amt);
    event Borrow    (address indexed u, uint256 dai, uint256 eth);
    event Repay     (address indexed u, uint256 dai);
    event Liquidate (address indexed user, address liquidator);

    constructor(IERC20 dai, uint256 ipbWeiPerBlock)
        Ownable(msg.sender)
    {
        DAI = dai;
        interestPerBlock = ipbWeiPerBlock;
    }

    /* ========== Deposit / Withdraw ========== */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "zero deposit");
        Account storage a = accounts[msg.sender];
        _accrue(a);

        DAI.safeTransferFrom(msg.sender, address(this), amount);
        a.deposit += amount;
        balanceOf[msg.sender] += amount;
        totalSupply += amount;

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 shares) external nonReentrant {
        require(shares > 0, "zero shares");
        Account storage a = accounts[msg.sender];
        _accrue(a);
        require(balanceOf[msg.sender] >= shares, "insufficient shares");

        a.deposit -= shares;
        balanceOf[msg.sender] -= shares;
        totalSupply -= shares;

        require(_health(a) >= 1e18, "under-collateral"); // ← ASCII hyphen
        DAI.safeTransfer(msg.sender, shares);
        emit Withdraw(msg.sender, shares);
    }

    /* ========== Borrow / Repay ========== */
    function borrow(uint256 daiAmount) external payable nonReentrant {
        require(daiAmount > 0 && msg.value > 0, "invalid params");

        Account storage a = accounts[msg.sender];
        _accrue(a);

        a.debt    += daiAmount;
        a.collETH += msg.value;

        require(_health(a) >= 1e18, "above LTV only");
        DAI.safeTransfer(msg.sender, daiAmount);
        emit Borrow(msg.sender, daiAmount, msg.value);
    }

    function repay(uint256 daiAmount) external nonReentrant {
        Account storage a = accounts[msg.sender];
        _accrue(a);
        require(daiAmount > 0 && daiAmount <= a.debt, "bad repay");

        DAI.safeTransferFrom(msg.sender, address(this), daiAmount);
        a.debt -= daiAmount;
        emit Repay(msg.sender, daiAmount);
    }

    /* ========== Liquidation ========== */
    function liquidate(address user) external nonReentrant {
        Account storage a = accounts[user];
        _accrue(a);
        require(_health(a) < 1e18, "healthy");

        uint256 repay = a.debt;
        DAI.safeTransferFrom(msg.sender, address(this), repay);

        uint256 ethPay = (repay * LIQ_BONUS_BP) / 1e4;
        require(ethPay <= a.collETH, "math");

        a.debt = 0;
        a.collETH -= ethPay;
        payable(msg.sender).transfer(ethPay);
        emit Liquidate(user, msg.sender);
    }

    /* ========== Internal helpers ========== */
    function _accrue(Account storage a) private {
        if (a.debt == 0) { a.lastBlock = block.number; return; }
        uint256 delta = block.number - a.lastBlock;
        uint256 interest = (delta * interestPerBlock * a.debt) / 1e18;
        a.debt += interest;
        a.lastBlock = block.number;
    }

    function _health(Account storage a) private view returns (uint256) {
        if (a.debt == 0) return type(uint256).max;
        uint256 ethPrice = 2000e18; // placeholder oracle
        uint256 collateralUSD = (a.collETH * ethPrice) / 1e18;
        return (collateralUSD * 1e18) / a.debt; // health factor
    }

    /* ========== Owner functions ========== */
    function setInterestPerBlock(uint256 ipb) external onlyOwner {
        interestPerBlock = ipb;
    }

    function rescueERC20(IERC20 tok, address to, uint256 amt) external onlyOwner {
        tok.safeTransfer(to, amt);
    }

    function rescueETH(address payable to, uint256 amt) external onlyOwner {
        to.transfer(amt);
    }
}
