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

/// ---------------------------------------------------------
/// 1) Smart Wallet (Multisig Execution)
/// ---------------------------------------------------------
contract SmartWallet is Base {
    mapping(address => bool) public isSigner;
    uint256 public signerCount;
    uint256 public threshold;
    uint256 public nonce;

    // --- Attack: anyone can execute
    function execInsecure(address to, uint256 value, bytes calldata data) external {
        // no auth or replay protection
        (bool ok,) = to.call{value: value}(data);
        require(ok, "Call failed");
    }

    // --- Defense: M-of-N multisig + nonce replay protection
    constructor(address[] memory signers, uint256 _threshold) {
        require(_threshold > 0 && _threshold <= signers.length, "Bad threshold");
        for (uint i; i < signers.length; i++) {
            isSigner[signers[i]] = true;
        }
        signerCount = signers.length;
        threshold   = _threshold;
    }

    function execSecure(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 _nonce,
        bytes[] calldata sigs
    ) external {
        require(_nonce == nonce, "Bad nonce");
        // build payload hash
        bytes32 h = keccak256(abi.encodePacked(address(this), to, value, data, _nonce));
        // verify multisig
        uint256 valid;
        address last;
        for (uint i; i < sigs.length; i++) {
            address signer = recover(h, sigs[i]);
            require(signer > last, "Duplicate or unordered");
            require(isSigner[signer], "Not signer");
            valid++; last = signer;
        }
        require(valid >= threshold, "Not enough sigs");
        // Effects
        nonce++;
        // Interaction
        (bool ok,) = to.call{value: value}(data);
        require(ok, "Call failed");
    }

    function recover(bytes32 h, bytes memory sig) internal pure returns(address) {
        bytes32 eth = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(sig, (bytes32,bytes32,uint8));
        return ecrecover(eth, v, r, s);
    }

    receive() external payable {}
}

/// ---------------------------------------------------------
/// 2) Smart Order Router
/// ---------------------------------------------------------
interface IERC20 {
    function transferFrom(address, address, uint256) external returns(bool);
}

contract OrderRouter is Base {
    // Dummy DEX interface
    function quote(address /*dex*/, uint256 /*amountIn*/) external pure returns(uint256) {
        return 0;
    }
    function swapOnDex(address dex, address tokenIn, address tokenOut, uint256 amountIn) internal returns(uint256) {
        // emulate swap
        return quote(dex, amountIn);
    }

    // --- Attack: no slippage or deadline, fixed route
    function swapInsecure(
        address dex,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        uint256 out = swapOnDex(dex, tokenIn, tokenOut, amountIn);
        // no minAmountOut check
        payable(msg.sender).transfer(out);
    }

    // --- Defense: check best quote, enforce slippage & deadline
    function swapSecure(
        address[] calldata dexs,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) external {
        require(block.timestamp <= deadline, "Deadline passed");
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        // find best DEX
        uint256 bestOut;
        address bestDex;
        for (uint i; i < dexs.length; i++) {
            uint256 o = quote(dexs[i], amountIn);
            if (o > bestOut) { bestOut = o; bestDex = dexs[i]; }
        }
        require(bestOut >= minAmountOut, "Slippage too high");
        uint256 out = swapOnDex(bestDex, tokenIn, tokenOut, amountIn);
        payable(msg.sender).transfer(out);
    }

    // Fund router for ETH swaps
    receive() external payable {}
}

/// ---------------------------------------------------------
/// 3) Portfolio Rebalancer
/// ---------------------------------------------------------
contract Rebalancer is Base, ReentrancyGuard {
    mapping(address => uint256) public allocation; // token ⇒ target pct in 1e4
    address[] public tokens;
    uint256 public maxPctSwap = 5000; // max 50% per job

    // --- Attack: anyone-called reentrancy & unlimited swap
    function rebalanceInsecure(uint256 /*amount*/) external {
        // anyone can call, no CEI, no cap
    }

    // --- Defense: onlyOwner, CEI, cap enforcement
    function rebalanceSecure(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Zero amount");
        require(amount <= address(this).balance * maxPctSwap / 10000, "Amount too large");
        // simplistic rebalance: distribute equally
        uint256 n = tokens.length;
        uint256 each = amount / n;
        for (uint i; i < n; i++) {
            payable(tokens[i]).transfer(each);
        }
    }

    function setTokens(address[] calldata _tokens, uint256[] calldata pcts) external onlyOwner {
        require(_tokens.length == pcts.length, "Len mismatch");
        uint256 sum;
        for (uint i; i < pcts.length; i++) sum += pcts[i];
        require(sum == 10000, "Must sum to 10000");
        tokens = _tokens;
        for (uint i; i < _tokens.length; i++) {
            allocation[_tokens[i]] = pcts[i];
        }
    }

    receive() external payable {}
}
