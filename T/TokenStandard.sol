// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TokenStandardModule - Minimal ERC Token Standard Implementations

// ==============================
// 🪙 ERC-20 Minimal
// ==============================
contract ERC20Token {
    string public name = "ERC20Token";
    string public symbol = "E20";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amt) external {
        balances[to] += amt;
        totalSupply += amt;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Insufficient");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function approve(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        return true;
    }

    function transferFrom(address from, address to, uint256 amt) external returns (bool) {
        require(balances[from] >= amt && allowance[from][msg.sender] >= amt, "Denied");
        balances[from] -= amt;
        balances[to] += amt;
        allowance[from][msg.sender] -= amt;
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

// ==============================
// 🎨 ERC-721 Minimal
// ==============================
contract ERC721Token {
    string public name = "ERC721Token";
    string public symbol = "E721";
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balances;

    function mint(address to, uint256 id) external {
        require(ownerOf[id] == address(0), "Exists");
        ownerOf[id] = to;
        balances[to]++;
    }

    function transferFrom(address from, address to, uint256 id) external {
        require(ownerOf[id] == from, "Not owner");
        ownerOf[id] = to;
        balances[from]--;
        balances[to]++;
    }
}

// ==============================
// 🧩 ERC-1155 Minimal
// ==============================
contract ERC1155Token {
    mapping(uint256 => mapping(address => uint256)) public balances;

    event TransferSingle(address indexed from, address indexed to, uint256 id, uint256 amount);

    function mint(address to, uint256 id, uint256 amt) external {
        balances[id][to] += amt;
        emit TransferSingle(msg.sender, to, id, amt);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amt) external {
        require(balances[id][from] >= amt, "Low balance");
        balances[id][from] -= amt;
        balances[id][to] += amt;
        emit TransferSingle(from, to, id, amt);
    }
}

// ==============================
// ⚙️ ERC-777 Mock (Send Hook Simulated)
// ==============================
contract ERC777Token {
    mapping(address => uint256) public balances;

    event Sent(address from, address to, uint256 amount);

    function mint(address to, uint256 amt) external {
        balances[to] += amt;
    }

    function send(address to, uint256 amt, bytes calldata data) external {
        require(balances[msg.sender] >= amt, "Low");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        emit Sent(msg.sender, to, amt);
        if (isContract(to)) {
            IERC777Receiver(to).tokensReceived(msg.sender, amt, data);
        }
    }

    function isContract(address a) internal view returns (bool) {
        return a.code.length > 0;
    }
}

interface IERC777Receiver {
    function tokensReceived(address from, uint256 amt, bytes calldata data) external;
}

// ==============================
// 🏦 ERC-4626 Vault (Minimal Simulation)
// ==============================
contract ERC4626Vault {
    ERC20Token public asset;
    mapping(address => uint256) public shares;
    uint256 public totalAssets;
    uint256 public totalShares;

    constructor(address _asset) {
        asset = ERC20Token(_asset);
    }

    function deposit(uint256 amt) external {
        asset.transferFrom(msg.sender, address(this), amt);
        uint256 share = totalShares == 0 ? amt : (amt * totalShares) / totalAssets;
        shares[msg.sender] += share;
        totalShares += share;
        totalAssets += amt;
    }

    function withdraw(uint256 share) external {
        uint256 amt = (share * totalAssets) / totalShares;
        shares[msg.sender] -= share;
        totalShares -= share;
        totalAssets -= amt;
        asset.transfer(msg.sender, amt);
    }
}
