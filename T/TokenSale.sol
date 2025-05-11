// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TokenSaleModule - Secure Token Sale System with Whitelist + Attack Simulation

// ==============================
// 🪙 Sale Token (ERC20)
// ==============================
contract SaleToken {
    string public name = "SaleToken";
    string public symbol = "SALE";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public minter;

    mapping(address => uint256) public balances;

    constructor() {
        minter = msg.sender;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Not minter");
        _;
    }

    function mint(address to, uint256 amt) external onlyMinter {
        balances[to] += amt;
        totalSupply += amt;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Low balance");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

// ==============================
// 🔐 Secure Token Sale
// ==============================
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract ReentrancyGuard {
    bool internal locked;
    modifier nonReentrant() {
        require(!locked, "Reentrant");
        locked = true;
        _;
        locked = false;
    }
}

contract TokenSale is ReentrancyGuard {
    SaleToken public token;
    bytes32 public merkleRoot;
    uint256 public tokenPrice = 0.01 ether; // per token
    uint256 public totalSold;
    uint256 public maxSupply;
    uint256 public startTime;
    uint256 public endTime;
    mapping(address => uint256) public purchased;
    mapping(address => bool) public claimed;

    event Purchased(address indexed buyer, uint256 amount);
    event Claimed(address indexed user, uint256 amount);

    constructor(
        address _token,
        uint256 _maxSupply,
        uint256 _start,
        uint256 _end,
        bytes32 _root
    ) {
        token = SaleToken(_token);
        maxSupply = _maxSupply;
        startTime = _start;
        endTime = _end;
        merkleRoot = _root;
    }

    function buy(uint256 amount, uint256 cap, bytes32[] calldata proof) external payable {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Not active");
        require(msg.value == amount * tokenPrice, "Wrong ETH");
        require(totalSold + amount <= maxSupply, "Max sold");
        require(purchased[msg.sender] + amount <= cap, "User cap exceeded");

        bytes32 node = keccak256(abi.encodePacked(msg.sender, cap));
        require(MerkleProof.verify(proof, merkleRoot, node), "Invalid proof");

        purchased[msg.sender] += amount;
        totalSold += amount;
        emit Purchased(msg.sender, amount);
    }

    function claim() external nonReentrant {
        require(!claimed[msg.sender], "Already claimed");
        uint256 amt = purchased[msg.sender];
        require(amt > 0, "Nothing");

        claimed[msg.sender] = true;
        token.mint(msg.sender, amt * 1 ether);
        emit Claimed(msg.sender, amt);
    }

    function withdrawETH(address to) external {
        require(msg.sender == address(token), "Admin only");
        payable(to).transfer(address(this).balance);
    }

    receive() external payable {}
}

// ==============================
// 🔓 Attacker: Early Entry / Double Claim
// ==============================
interface ITokenSale {
    function buy(uint256, uint256, bytes32[] calldata) external payable;
    function claim() external;
}

contract TokenSaleAttacker {
    ITokenSale public target;

    constructor(address _target) {
        target = ITokenSale(_target);
    }

    function earlyBuy(uint256 amount, uint256 cap, bytes32[] calldata proof) external payable {
        target.buy{value: msg.value}(amount, cap, proof);
    }

    function doubleClaim() external {
        target.claim();
        target.claim(); // should fail
    }
}
