// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GoldBackedToken {
    string public name = "GoldToken";
    string public symbol = "GOLD";
    uint8 public decimals = 18;

    address public custodian;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    modifier onlyCustodian() {
        require(msg.sender == custodian, "Not authorized");
        _;
    }

    constructor(address _custodian) {
        custodian = _custodian;
    }

    // Mint tokens to users who deposit physical gold
    function mint(address to, uint256 amount) external onlyCustodian {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Minted(to, amount);
        emit Transfer(address(0), to, amount);
    }

    // Burn tokens to simulate redemption
    function burn(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Not enough GOLD");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Burned(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    // Standard ERC20 transfer
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Not enough GOLD");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // Approve spender
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // Transfer from (for spending on behalf)
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");

        balanceOf[from] -= amount;
        allowance[from][msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }
}
