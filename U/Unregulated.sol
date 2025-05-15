// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title UnregulatedTokenLauncher - Deploys ERC20s with no compliance enforcement
contract UnregulatedTokenLauncher {
    address[] public tokens;

    event TokenDeployed(address indexed creator, address token, string name, string symbol);

    function launchToken(string memory name, string memory symbol, uint256 supply) external {
        ERC20Token token = new ERC20Token(name, symbol, supply, msg.sender);
        tokens.push(address(token));
        emit TokenDeployed(msg.sender, address(token), name, symbol);
    }

    function getAllTokens() external view returns (address[] memory) {
        return tokens;
    }
}

/// @notice Lightweight ERC20 with no access control, KYC, or limits
contract ERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public creator;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(string memory _name, string memory _symbol, uint256 _supply, address _creator) {
        name = _name;
        symbol = _symbol;
        creator = _creator;
        totalSupply = _supply * 1e18;
        balances[_creator] = totalSupply;
        emit Transfer(address(0), _creator, totalSupply);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balances[msg.sender] >= amount, "Not enough");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balances[from] >= amount, "Not enough");
        require(allowance[from][msg.sender] >= amount, "Not allowed");
        balances[from] -= amount;
        balances[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}
