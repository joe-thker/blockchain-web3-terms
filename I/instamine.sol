// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title 1. Hardcoded Instamine
/// @notice All tokens are minted immediately to a dev wallet.
contract HardcodedInstamine is ERC20 {
    constructor(address dev) ERC20("HardInstamine", "HIM") {
        _mint(dev, 1_000_000 * 1e18);
    }
}

/// @title 2. Loop-Based Instamine (Abusive Mint)
/// @notice Mints a huge amount via a loop early on.
contract LoopInstamine is ERC20, Ownable {
    bool public mined;

    constructor() ERC20("LoopInstamine", "LIM") Ownable(msg.sender) {}

    function instamine(address to) external onlyOwner {
        require(!mined, "Already mined");
        for (uint256 i = 0; i < 100; i++) {
            _mint(to, 10_000 * 1e18);
        }
        mined = true;
    }
}

/// @title 3. Difficulty/Timing Exploit Sim (Simulated PoW bug)
/// @notice Allows instant minting at launch with no restriction.
contract DifficultyBugInstamine is ERC20, Ownable {
    uint256 public launchTime;
    bool public mined;

    constructor() ERC20("BugInstamine", "BIM") Ownable(msg.sender) {
        launchTime = block.timestamp;
    }

    function mineEarly(address to) external onlyOwner {
        require(block.timestamp <= launchTime + 10 minutes, "Too late");
        require(!mined, "Already mined");
        _mint(to, 2_000_000 * 1e18);
        mined = true;
    }
}

/// @title 4. Airdrop Instamine
/// @notice Pretends to be a fair drop but drops 99% to insiders.
contract AirdropInstamine is ERC20, Ownable {
    constructor(address[] memory insiders) ERC20("AirdropInstamine", "AIM") Ownable(msg.sender) {
        uint256 total = 1_000_000 * 1e18;
        uint256 insiderShare = (total * 99) / 100;
        uint256 each = insiderShare / insiders.length;

        for (uint256 i = 0; i < insiders.length; i++) {
            _mint(insiders[i], each);
        }

        _mint(msg.sender, total - insiderShare); // rest to owner
    }
}

/// @title 5. Backdoor Mint Instamine
/// @notice Contract includes hidden mint function callable by dev
contract BackdoorInstamine is ERC20, Ownable {
    bool public leaked;

    constructor() ERC20("BackdoorInstamine", "BDM") Ownable(msg.sender) {
        _mint(msg.sender, 100_000 * 1e18);
    }

    function leakMint(address to, uint256 amount) external onlyOwner {
        require(!leaked, "Already used");
        leaked = true;
        _mint(to, amount);
    }
}
