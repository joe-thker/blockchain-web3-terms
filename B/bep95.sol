// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IBEP20 Interface
/// @notice Minimal interface for BEP-20 tokens.
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

/// @title BEP95Token
/// @notice A simplified BEP‑95 basket token representing a basket of two underlying tokens.
contract BEP95Token {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public owner;

    // Mapping from addresses to BEP95 token balances.
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Underlying tokens and required deposit ratios.
    IBEP20 public tokenA;
    IBEP20 public tokenB;
    // For example, if the basket requires a 50:50 split, ratioA = 50e18, ratioB = 50e18.
    uint256 public ratioA;
    uint256 public ratioB;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed user, uint256 amountMinted);
    event Redeem(address indexed user, uint256 amountRedeemed);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor to initialize the basket token.
    /// @param _name Token name.
    /// @param _symbol Token symbol.
    /// @param _tokenA Address of underlying token A.
    /// @param _tokenB Address of underlying token B.
    /// @param _ratioA Required ratio for token A (e.g., 50e18 for 50%).
    /// @param _ratioB Required ratio for token B (e.g., 50e18 for 50%).
    constructor(
        string memory _name,
        string memory _symbol,
        address _tokenA,
        address _tokenB,
        uint256 _ratioA,
        uint256 _ratioB
    ) {
        require(_ratioA + _ratioB == 1e18, "Ratios must sum to 1e18");
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        tokenA = IBEP20(_tokenA);
        tokenB = IBEP20(_tokenB);
        ratioA = _ratioA;
        ratioB = _ratioB;
    }

    /// @notice Transfers BEP95 tokens.
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Transfer to zero address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Approves spender to spend tokens on behalf of caller.
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Approve to zero address");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Transfers tokens from sender to recipient using allowance.
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(sender != address(0) && recipient != address(0), "Zero address");
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Allowance exceeded");
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /// @notice Deposits underlying tokens to mint new BEP95 basket tokens.
    /// The deposit amounts must be in the proportion defined by ratioA and ratioB.
    function deposit(uint256 amountA, uint256 amountB) public {
        // Check the deposit ratios: amountA/amountB should equal ratioA/ratioB.
        // To avoid floating-point division, cross-multiply:
        require(amountA * ratioB == amountB * ratioA, "Deposit amounts must match required ratio");

        // Transfer underlying tokens from the user to this contract.
        require(tokenA.transferFrom(msg.sender, address(this), amountA), "Token A transfer failed");
        require(tokenB.transferFrom(msg.sender, address(this), amountB), "Token B transfer failed");

        // For simplicity, mint new BEP95 tokens equal to the sum of the deposited amounts.
        uint256 mintAmount = amountA + amountB;
        balanceOf[msg.sender] += mintAmount;
        totalSupply += mintAmount;
        emit Mint(msg.sender, mintAmount);
        emit Transfer(address(0), msg.sender, mintAmount);
    }

    /// @notice Redeems BEP95 tokens to withdraw underlying tokens in the basket.
    function redeem(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient BEP95 balance");
        // Burn BEP95 tokens.
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        emit Redeem(msg.sender, amount);

        // Calculate how many underlying tokens to return.
        // Assume the minted amount was the sum of deposits.
        // Then, tokenA amount = amount * ratioA, tokenB amount = amount * ratioB.
        uint256 redeemA = amount * ratioA / 1e18;
        uint256 redeemB = amount * ratioB / 1e18;

        require(tokenA.transfer(msg.sender, redeemA), "Token A transfer failed");
        require(tokenB.transfer(msg.sender, redeemB), "Token B transfer failed");
    }
}
