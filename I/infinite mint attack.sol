// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Type 1: Public Mint Function (No Access Control)
contract MintAttackPublic is ERC20 {
    constructor() ERC20("BadToken", "BAD") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount); // ❌ Anyone can mint
    }
}

/// @title Type 2: Broken Access Control (Improper Modifier)
contract MintAttackBrokenAccess is ERC20 {
    address public admin;

    constructor() ERC20("VulnToken", "VULN") {
        admin = msg.sender;
    }

    // ❌ Incorrect check — always true if called by anyone
    function mint(address to, uint256 amount) external {
        require(tx.origin == admin, "Not admin");
        _mint(to, amount);
    }
}

/// @title Type 3: Logic Flaw (Always True Condition)
contract MintAttackLogicBug is ERC20 {
    constructor() ERC20("BuggyToken", "BUG") {}

    function mintIfAllowed(address to, uint256 amount) external {
        if (to != address(0) || to == address(0)) { // ❌ Always true
            _mint(to, amount);
        }
    }
}

/// @title Type 4: Unchecked Max Supply or Cap
contract MintAttackNoCap is ERC20 {
    constructor() ERC20("UncappedToken", "UNCAP") {
        _mint(msg.sender, 100_000 * 1e18);
    }

    function mint(address to, uint256 amount) external {
        // ❌ No max supply check
        _mint(to, amount);
    }
}

/// @title Type 5: Upgradeable Token with Overridable Mint
contract MintAttackUpgradeable is ERC20 {
    address public owner;

    constructor() ERC20("ProxyToken", "PROXY") {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "Only owner");
        _mint(to, amount);
    }

    // ❌ Can be overridden in proxy logic to remove the `require`
}
