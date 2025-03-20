// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IBEP20
/// @notice Interface for BEP-20 standard tokens.
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// @title BEP20Token
/// @notice A simple BEP-20 token implementation on EVM-compatible chains (e.g., Binance Smart Chain).
contract BEP20Token is IBEP20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice Constructor to initialize the token.
    /// @param _name The name of the token.
    /// @param _symbol The symbol of the token.
    /// @param _decimals The number of decimals for the token.
    /// @param totalSupply_ The initial total supply of tokens.
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 totalSupply_
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _totalSupply = totalSupply_;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /// @notice Returns the total token supply.
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /// @notice Returns the token balance of an account.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /// @notice Transfers tokens to a recipient.
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(_balances[msg.sender] >= amount, "BEP20: transfer amount exceeds balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Returns the remaining number of tokens that spender is allowed to spend on behalf of owner.
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @notice Approves spender to spend a certain amount of tokens.
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Transfers tokens on behalf of the owner.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(_balances[sender] >= amount, "BEP20: transfer amount exceeds balance");
        require(_allowances[sender][msg.sender] >= amount, "BEP20: transfer amount exceeds allowance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}
