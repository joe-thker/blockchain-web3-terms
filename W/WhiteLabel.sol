// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title WhiteLabelDEXFactory - Deploys customizable ERC20 swap pairs under client brand
contract WhiteLabelDEXFactory {
    address public immutable admin;
    address[] public deployedPairs;

    event PoolCreated(address pair, address tokenA, address tokenB, uint256 feeRate, string brand);

    constructor() {
        admin = msg.sender;
    }

    function createPair(
        address tokenA,
        address tokenB,
        uint256 feeRate, // e.g., 0.3% = 30 = 0.3e2
        string calldata brand
    ) external returns (address pair) {
        require(tokenA != tokenB, "Identical tokens");
        require(feeRate <= 1000, "Too high"); // Max 10%

        bytes memory bytecode = type(WhiteLabelPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB, msg.sender));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        WhiteLabelPair(pair).init(tokenA, tokenB, feeRate, msg.sender, brand);
        deployedPairs.push(pair);
        emit PoolCreated(pair, tokenA, tokenB, feeRate, brand);
    }

    function getAllPairs() external view returns (address[] memory) {
        return deployedPairs;
    }
}

/// @title WhiteLabelPair - Minimal ERC20 DEX pair contract with branding
contract WhiteLabelPair {
    address public tokenA;
    address public tokenB;
    address public owner;
    uint256 public feeRate; // e.g., 30 = 0.3%
    string public brand;

    bool public initialized;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function init(
        address _tokenA,
        address _tokenB,
        uint256 _feeRate,
        address _owner,
        string memory _brand
    ) external {
        require(!initialized, "Already initialized");
        tokenA = _tokenA;
        tokenB = _tokenB;
        feeRate = _feeRate;
        owner = _owner;
        brand = _brand;
        initialized = true;
    }

    function swap(address fromToken, uint256 amount) external {
        require(fromToken == tokenA || fromToken == tokenB, "Invalid token");

        address toToken = fromToken == tokenA ? tokenB : tokenA;
        IERC20(fromToken).transferFrom(msg.sender, address(this), amount);

        uint256 fee = (amount * feeRate) / 10000;
        uint256 amountOut = amount - fee;

        require(IERC20(toToken).balanceOf(address(this)) >= amountOut, "Insufficient liquidity");
        IERC20(toToken).transfer(msg.sender, amountOut);
    }

    function deposit(address token, uint256 amount) external onlyOwner {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }
}

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}
