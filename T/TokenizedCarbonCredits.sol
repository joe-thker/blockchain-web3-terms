// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TokenizedCarbonCreditModule - Carbon Credit ERC20/ERC721 with retirement + attack simulation

// ==============================
// 🪙 ERC20 Carbon Credit Token (1 token = 1 ton CO₂)
// ==============================
contract CarbonCredit {
    string public name = "Carbon Ton";
    string public symbol = "CO2T";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public issuer;
    mapping(address => uint256) public balances;

    constructor() {
        issuer = msg.sender;
    }

    modifier onlyIssuer() {
        require(msg.sender == issuer, "Not issuer");
        _;
    }

    function mint(address to, uint256 amt) external onlyIssuer {
        balances[to] += amt;
        totalSupply += amt;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Insufficient");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function burn(address from, uint256 amt) external onlyIssuer {
        require(balances[from] >= amt, "Too much");
        balances[from] -= amt;
        totalSupply -= amt;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

// ==============================
// 🔐 Carbon Retirement Vault (Burn + Event Logging)
// ==============================
contract CarbonRetirement {
    CarbonCredit public token;
    mapping(address => uint256) public retired;

    event CarbonRetired(address indexed user, uint256 amount, string reason, uint256 timestamp);

    constructor(address _token) {
        token = CarbonCredit(_token);
    }

    function retire(uint256 amt, string calldata reason) external {
        require(token.balanceOf(msg.sender) >= amt, "Not enough");
        token.burn(msg.sender, amt);
        retired[msg.sender] += amt;
        emit CarbonRetired(msg.sender, amt, reason, block.timestamp);
    }
}

// ==============================
// 🌍 ERC721 Carbon Project NFT (Project Tracking)
// ==============================
contract CarbonNFT {
    string public name = "Carbon Project";
    string public symbol = "CO2P";

    uint256 public nextId;
    address public registry;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => string) public uri;
    mapping(uint256 => bytes32) public projectHash;
    mapping(uint256 => bool) public frozen;

    event ProjectMinted(address indexed to, uint256 indexed id, string meta);
    event MetadataFrozen(uint256 indexed id);

    constructor() {
        registry = msg.sender;
    }

    function mint(address to, string calldata _uri, bytes32 projectIdHash) external returns (uint256) {
        require(msg.sender == registry, "Not registry");
        uint256 id = nextId++;
        ownerOf[id] = to;
        uri[id] = _uri;
        projectHash[id] = projectIdHash;
        emit ProjectMinted(to, id, _uri);
        return id;
    }

    function freeze(uint256 id) external {
        require(msg.sender == ownerOf[id], "Not owner");
        frozen[id] = true;
        emit MetadataFrozen(id);
    }
}

// ==============================
// 🔓 Fake Issuer / Attacker (Unauthorized Mint Attempt)
// ==============================
interface ICarbonCredit {
    function mint(address, uint256) external;
}

contract FakeIssuer {
    function exploitMint(ICarbonCredit target, uint256 amt) external {
        target.mint(msg.sender, amt); // Should fail if not issuer
    }
}
