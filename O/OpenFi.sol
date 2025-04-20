// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * OpenFi Lending Pool (single‑asset demo)
 * --------------------------------------
 * – Deposit DAI → receive oDAI receipt tokens (1:1).
 * – Borrow DAI against ETH collateral (60 % LTV).
 * – Flat per‑block interest; 110 % liquidation bonus.
 *
 *  FIX: replaced Unicode en‑dash in the revert string with an
 *       ASCII hyphen, removing the Solidity parser error.
 */
contract OpenFiPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* immutable params */
    IERC20 public immutable DAI;
    uint16 public constant LTV_BP       = 6000;  // 60 %
    uint16 public constant LIQ_BONUS_BP = 11000; // 110 %
    uint256 public interestPerBlock;             // 1e18‑scaled

    /* pseudo‑ERC‑20 receipt token */
    string  public constant name     = "OpenFi Deposit DAI";
    string  public constant symbol   = "oDAI";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    /* user state */
    struct Account {
        uint256 deposit;   // DAI
        uint256 debt;      // DAI
        uint256 collETH;   // wei
        uint256 lastBlock; // accrual
    }
    mapping(address => Account) public accounts;

    /* events */
    event Deposit   (address indexed u, uint256 amount);
    event Withdraw  (address indexed u, uint256 amount);
    event Borrow    (address indexed u, uint256 dai, uint256 eth);
    event Repay     (address indexed u, uint256 dai);
    event Liquidate (address indexed user, address liquidator);

    constructor(IERC20 dai, uint256 ipbWeiPerBlock)
        Ownable(msg.sender)
    {
        DAI = dai;
        interestPerBlock = ipbWeiPerBlock;
    }

    /* ------------- deposit / withdraw ------------- */
    function deposit(uint256 amt) external nonReentrant {
        require(amt > 0, "zero");
        Account storage a = accounts[msg.sender];
        _accrue(a);

        DAI.safeTransferFrom(msg.sender, address(this), amt);
        a.deposit += amt;
        balanceOf[msg.sender] += amt;
        totalSupply += amt;

        emit Deposit(msg.sender, amt);
    }

    function withdraw(uint256 shares) external nonReentrant {
        Account storage a = accounts[msg.sender];
        _accrue(a);
        require(balanceOf[msg.sender] >= shares, "oDAI too low");

        a.deposit -= shares;
        balanceOf[msg.sender] -= shares;
        totalSupply -= shares;

        require(_health(a) >= 1e18, "would under-collateralise"); // ← ASCII hyphen
        DAI.safeTransfer(msg.sender, shares);
        emit Withdraw(msg.sender, shares);
    }

    /* ------------- borrow / repay ------------- */
    function borrow(uint256 daiAmt) external payable nonReentrant {
        require(daiAmt > 0 && msg.value > 0, "bad params");
        Account storage a = accounts[msg.sender];
        _accrue(a);

        a.debt    += daiAmt;
        a.collETH += msg.value;
        require(_health(a) >= 1e18, "above LTV");

        DAI.safeTransfer(msg.sender, daiAmt);
        emit Borrow(msg.sender, daiAmt, msg.value);
    }

    function repay(uint256 daiAmt) external nonReentrant {
        Account storage a = accounts[msg.sender];
        _accrue(a);
        require(daiAmt > 0 && daiAmt <= a.debt, "bad repay");

        DAI.safeTransferFrom(msg.sender, address(this), daiAmt);
        a.debt -= daiAmt;
        emit Repay(msg.sender, daiAmt);
    }

    /* ------------- liquidation ------------- */
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

    /* ------------- internal helpers ------------- */
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
        uint256 collUSD  = (a.collETH * ethPrice) / 1e18;
        return (collUSD * 1e18) / a.debt;
    }

    /* ------------- owner controls ------------- */
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
