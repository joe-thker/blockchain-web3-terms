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

interface IERC20 {
    function transferFrom(address, address, uint256) external returns(bool);
    function transfer(address, uint256) external returns(bool);
}

/// ---------------------------------------------------------
/// 1) DEX Swap Sniper
/// ---------------------------------------------------------
contract DexSniper is Base {
    IERC20 public tokenIn;
    IERC20 public tokenOut;
    uint112 public reserveIn;
    uint112 public reserveOut;
    uint256 public maxGasPrice = 100 gwei;

    // --- Attack: no slippage or deadline checks
    function swapInsecure(uint256 amountIn) external {
        require(tx.gasprice <= type(uint256).max, "Any gas price");
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        uint256 out = reserveOut * amountIn / reserveIn;
        reserveIn += uint112(amountIn);
        reserveOut -= uint112(out);
        tokenOut.transfer(msg.sender, out);
    }

    // --- Defense: require minOut, deadline, gas cap
    function swapSecure(
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) external {
        require(block.timestamp <= deadline, "Deadline passed");
        require(tx.gasprice <= maxGasPrice, "Gas too high");
        tokenIn.transferFrom(msg.sender, address(this), amountIn);

        uint256 amountInWithFee = amountIn * 997 / 1000;
        uint256 numerator   = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        uint256 out        = numerator / denominator;
        require(out >= minAmountOut, "Slippage too high");

        reserveIn  += uint112(amountIn);
        reserveOut -= uint112(out);
        tokenOut.transfer(msg.sender, out);
    }

    function initReserves(uint112 rIn, uint112 rOut) external onlyOwner {
        reserveIn = rIn;
        reserveOut = rOut;
    }
}

/// ---------------------------------------------------------
/// 2) NFT Mint Sniper
/// ---------------------------------------------------------
contract NftSniper is Base {
    mapping(address => uint256) public minted;
    uint256 public perTxCap = 1;
    uint256 public perWalletCap = 5;
    bool public whitelistOnly;
    uint256 public mintStart;
    uint256 public maxGasPrice = 100 gwei;
    mapping(address => bool) public whitelisted;

    // --- Attack: unlimited mint any time
    function mintInsecure(uint256 qty) external payable {
        // no timing, no caps
        minted[msg.sender] += qty;
        // mint logic...
    }

    // --- Defense: timing, caps, whitelist, gas cap
    function mintSecure(uint256 qty) external payable {
        require(block.timestamp >= mintStart, "Mint not started");
        require(tx.gasprice <= maxGasPrice, "Gas too high");
        if (whitelistOnly) {
            require(whitelisted[msg.sender], "Not whitelisted");
        }
        require(qty <= perTxCap, "Per-tx cap");
        require(minted[msg.sender] + qty <= perWalletCap, "Per-wallet cap");

        minted[msg.sender] += qty;
        // mint logic...
    }

    function setParameters(
        bool _wl,
        uint256 _start,
        uint256 _perTx,
        uint256 _perW
    ) external onlyOwner {
        whitelistOnly = _wl;
        mintStart     = _start;
        perTxCap      = _perTx;
        perWalletCap  = _perW;
    }
    function setWhitelist(address user, bool ok) external onlyOwner {
        whitelisted[user] = ok;
    }
}

/// ---------------------------------------------------------
/// 3) Auction Sniper
/// ---------------------------------------------------------
contract AuctionSniper is Base, ReentrancyGuard {
    struct Auction { uint256 endTime; uint256 highestBid; address highestBidder; bool active; }
    mapping(uint256 => Auction) public auctions;
    uint256 public bidIncrementBP = 100; // 1%
    uint256 public extendWindow = 5 minutes;

    // --- Attack: bid at last block, tiny increment, repeated
    function bidInsecure(uint256 aucId) external payable {
        Auction storage a = auctions[aucId];
        require(a.active, "No such auction");
        require(block.timestamp <= a.endTime, "Ended");
        // no increment check
        a.highestBid = msg.value;
        a.highestBidder = msg.sender;
        // no anti-sniping
    }

    // --- Defense: min increment, anti-sniping extend, once per bidder per auction
    function bidSecure(uint256 aucId) external payable nonReentrant {
        Auction storage a = auctions[aucId];
        require(a.active, "No such auction");
        require(block.timestamp <= a.endTime, "Ended");

        uint256 minBid = a.highestBid + (a.highestBid * bidIncrementBP / 10000);
        require(msg.value >= minBid, "Below min increment");

        // refund previous
        if (a.highestBidder != address(0)) {
            payable(a.highestBidder).transfer(a.highestBid);
        }

        a.highestBid = msg.value;
        a.highestBidder = msg.sender;

        // extend if sniped near end
        if (a.endTime - block.timestamp < extendWindow) {
            a.endTime = block.timestamp + extendWindow;
        }
    }

    function createAuction(uint256 aucId, uint256 duration) external onlyOwner {
        auctions[aucId] = Auction(block.timestamp + duration, 0, address(0), true);
    }

    function finalize(uint256 aucId) external nonReentrant {
        Auction storage a = auctions[aucId];
        require(block.timestamp > a.endTime, "Not ended");
        a.active = false;
        if (a.highestBidder != address(0)) {
            // send item to winner, ETH stays in contract
        }
    }
}
