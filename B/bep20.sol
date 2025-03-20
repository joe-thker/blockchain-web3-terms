// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IBEP20 Interface
/// @notice Standard interface for BEP-20 tokens.
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
/// @notice A BEP-20 token implementation on Binance Smart Chain.
contract BEP20Token is IBEP20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;

    // Mapping from addresses to their balances.
    mapping(address => uint256) private _balances;
    // Mapping from owner to spender approvals.
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice Constructor to initialize the token.
    /// @param _name The token name.
    /// @param _symbol The token symbol.
    /// @param _decimals The number of decimals the token uses.
    /// @param totalSupply_ The initial total supply of the token.
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
        // Assign the total supply to the contract deployer.
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /// @notice Returns the total token supply.
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /// @notice Returns the balance of the specified account.
    /// @param account The account address.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /// @notice Transfers tokens to a specified recipient.
    /// @param recipient The recipient address.
    /// @param amount The amount to transfer.
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(_balances[msg.sender] >= amount, "BEP20: transfer amount exceeds balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Returns the amount that spender is allowed to spend on behalf of owner.
    /// @param owner The owner of the tokens.
    /// @param spender The spender address.
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @notice Approves spender to spend a specified amount of tokens on behalf of the caller.
    /// @param spender The spender address.
    /// @param amount The amount to approve.
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Transfers tokens from one address to another using the allowance mechanism.
    /// @param sender The address to transfer tokens from.
    /// @param recipient The recipient address.
    /// @param amount The amount to transfer.
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
