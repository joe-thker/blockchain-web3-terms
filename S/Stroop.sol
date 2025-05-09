// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

///////////////////////////////////////////////////////////////////////////
// 1) Test Item Registry
///////////////////////////////////////////////////////////////////////////
contract StroopRegistry {
    address public owner;
    uint256 public constant MAX_ITEMS = 100;

    struct Item { string word; uint8 correctColor; bool exists; }
    mapping(uint256 => Item) public items;
    uint256 public itemCount;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // --- Attack: anyone can add items, duplicates allowed
    function addItemInsecure(string calldata word, uint8 color) external {
        items[itemCount++] = Item(word, color, true);
    }

    // --- Defense: onlyOwner + cap + no duplicates
    function addItemSecure(string calldata word, uint8 color) external onlyOwner {
        require(itemCount < MAX_ITEMS, "Max items reached");
        // simple duplicate check
        for (uint i = 0; i < itemCount; i++) {
            Item storage it = items[i];
            if (keccak256(bytes(it.word)) == keccak256(bytes(word))
                && it.correctColor == color) {
                revert("Duplicate item");
            }
        }
        items[itemCount++] = Item(word, color, true);
    }

    // --- Attack: anyone can remove any item
    function removeItemInsecure(uint256 id) external {
        delete items[id];
    }

    // --- Defense: onlyOwner can remove
    function removeItemSecure(uint256 id) external onlyOwner {
        delete items[id];
    }
}

///////////////////////////////////////////////////////////////////////////
// 2) Guess Submission
///////////////////////////////////////////////////////////////////////////
contract StroopGame is StroopRegistry {
    // reuse owner, items
    mapping(address => mapping(uint256 => uint256)) public nonces; // user→item→nonce

    event Guess(address user, uint256 itemId, uint8 guessColor);

    // --- Attack: no validation or replay protection
    function submitGuessInsecure(uint256 itemId, uint8 guessColor) external {
        emit Guess(msg.sender, itemId, guessColor);
    }

    // --- Defense: validate answer + per‐user per‐item nonce
    function submitGuessSecure(
        uint256 itemId,
        uint8 guessColor,
        uint256 nonce
    ) external {
        Item storage it = items[itemId];
        require(it.exists, "Invalid item");
        require(nonce > nonces[msg.sender][itemId], "Replay guess");
        nonces[msg.sender][itemId] = nonce;
        require(guessColor < 256, "Bad color"); // sanity
        emit Guess(msg.sender, itemId, guessColor);

        // optional: record correctness off-chain or in next module
    }
}

///////////////////////////////////////////////////////////////////////////
// 3) Reward Claiming
///////////////////////////////////////////////////////////////////////////
contract StroopRewards is StroopGame, ReentrancyGuard {
    mapping(address => mapping(uint256 => bool)) public claimed; // user→item→claimed
    uint256 public rewardAmount = 1e18; // 1 token per correct guess
    IERC20  public rewardToken;

    constructor(IERC20 _rewardToken) StroopRegistry() {
        rewardToken = _rewardToken;
    }

    // --- Attack: allow double‐claim + reentrancy
    function claimRewardInsecure(uint256 itemId) external {
        // no correctness check, no claimed flag
        rewardToken.transfer(msg.sender, rewardAmount);
    }

    // --- Defense: require correct guess, track claimed, nonReentrant
    function claimRewardSecure(
        uint256 itemId,
        uint8 guessColor
    ) external nonReentrant {
        Item storage it = items[itemId];
        require(it.exists, "Invalid item");
        require(!claimed[msg.sender][itemId], "Already claimed");
        require(guessColor == it.correctColor, "Wrong guess");

        claimed[msg.sender][itemId] = true;         // Effects
        rewardToken.transfer(msg.sender, rewardAmount); // Interaction
    }
}

interface IERC20 {
    function transfer(address to, uint256 amt) external returns (bool);
}
