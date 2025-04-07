// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Method 1: Supply Cap Enforcement
contract CappedToken is ERC20Capped, Ownable {
    constructor() ERC20("CappedToken", "CAP") ERC20Capped(1_000_000 * 1e18) Ownable(msg.sender) {
        _mint(msg.sender, 100_000 * 1e18);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount); // cap enforced automatically
    }
}

/// @title Method 2: Time-Locked Minting
contract TimedMintToken is ERC20, Ownable {
    uint256 public lastMint;
    uint256 public mintCooldown = 1 days;

    constructor() ERC20("TimedMint", "TMT") Ownable(msg.sender) {
        lastMint = block.timestamp;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(block.timestamp >= lastMint + mintCooldown, "Cooldown not reached");
        _mint(to, amount);
        lastMint = block.timestamp;
    }
}

/// @title Method 3: Governance-Controlled Minting
contract GovMintToken is ERC20, Ownable {
    address public minter;

    constructor() ERC20("GovMint", "GMT") Ownable(msg.sender) {
        minter = msg.sender;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Not minter");
        _;
    }

    function setMinter(address newMinter) external onlyOwner {
        minter = newMinter;
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }
}

/// @title Method 4: Mint Rate Throttling
contract ThrottledMintToken is ERC20, Ownable {
    uint256 public maxDailyMint = 10_000 * 1e18;
    uint256 public mintedToday;
    uint256 public lastReset;

    constructor() ERC20("ThrottledMint", "THR") Ownable(msg.sender) {
        lastReset = block.timestamp;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        if (block.timestamp > lastReset + 1 days) {
            mintedToday = 0;
            lastReset = block.timestamp;
        }

        require(mintedToday + amount <= maxDailyMint, "Mint limit exceeded");
        _mint(to, amount);
        mintedToday += amount;
    }
}

/// @title Method 5: Burn Before Mint (Net Zero Policy)
contract BurnToMintToken is ERC20, Ownable {
    constructor() ERC20("BurnMint", "BMT") Ownable(msg.sender) {
        _mint(msg.sender, 100_000 * 1e18);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= 1_000_000 * 1e18, "Supply cap");
        _mint(to, amount);
    }
}
