// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BRC20Token
/// @notice This contract simulates a BRC-20 token on an EVM-compatible blockchain for educational purposes.
/// Note: Real BRC-20 tokens are created on Bitcoin using ordinal inscriptions, not Solidity.
contract BRC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Constructor to initialize the token.
    /// @param _name Token name.
    /// @param _symbol Token symbol.
    /// @param _decimals Number of decimals.
    /// @param _totalSupply Initial total supply.
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /// @notice Returns the token balance of a given account.
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /// @notice Transfers tokens from the caller to a recipient.
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Transfer to zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Returns the remaining number of tokens that spender is allowed to spend on behalf of owner.
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    /// @notice Approves spender to spend a given amount on behalf of the caller.
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Approve to zero address");
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Transfers tokens on behalf of owner using the allowance mechanism.
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(sender != address(0) && recipient != address(0), "Zero address");
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "Allowance exceeded");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}
