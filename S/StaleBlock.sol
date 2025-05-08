// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title StaleBlockPatterns
/// @notice Demonstrates insecure vs. secure patterns around stale block pitfalls

//////////////////////////////////////////////////////
// 1) Randomness via blockhash
//////////////////////////////////////////////////////
contract RandomStale {
    /// --- Attack: allow arbitrary block hashes, including stale >256 blocks back
    function randomInsecure(uint256 blk) external view returns (uint256) {
        // if blk < block.number - 256, blockhash returns 0 => predictable
        return uint256(blockhash(blk));
    }

    /// --- Defense: only allow immediate prior block
    function randomSecure() external view returns (uint256) {
        // enforce exactly one-block back
        uint256 blk = block.number - 1;
        bytes32 h = blockhash(blk);
        require(h != bytes32(0), "Blockhash unavailable");
        return uint256(h);
    }
}

//////////////////////////////////////////////////////
// 2) Time-based Logic with block.timestamp
//////////////////////////////////////////////////////
contract DeadlineStale {
    uint256 public deadlineTs;
    uint256 public deadlineBlk;

    constructor(uint256 delaySeconds, uint256 delayBlocks) {
        // set both a timestamp and block-number deadline
        deadlineTs  = block.timestamp + delaySeconds;
        deadlineBlk = block.number   + delayBlocks;
    }

    /// --- Attack: miner manipulates timestamp to slip in late bids
    function bidInsecure() external view returns (string memory) {
        require(block.timestamp <= deadlineTs, "Too late");
        return "Accepted";
    }

    /// --- Defense: combine with block-number cutoff
    function bidSecure() external view returns (string memory) {
        require(block.timestamp <= deadlineTs, "Time passed");
        require(block.number   <= deadlineBlk, "Block limit passed");
        return "Accepted securely";
    }
}

//////////////////////////////////////////////////////
// 3) Confirmation Finality
//////////////////////////////////////////////////////
contract FinalityStale is ReentrancyGuard {
    struct Deposit { uint256 amount; uint256 blockNumber; }

    mapping(address => Deposit) public deposits;
    uint256 public constant REQUIRED_CONFIRMATIONS = 6;

    /// User deposits ETH; we record its block number
    function deposit() external payable {
        deposits[msg.sender] = Deposit(msg.value, block.number);
    }

    /// --- Attack: act immediately on deposit; a 0-conf reorg could undo it
    function withdrawInsecure() external nonReentrant {
        uint256 amt = deposits[msg.sender].amount;
        require(amt > 0, "No deposit");
        deposits[msg.sender].amount = 0;
        payable(msg.sender).transfer(amt);
    }

    /// --- Defense: require N confirmations so the deposit block isn't stale
    function withdrawSecure() external nonReentrant {
        Deposit storage d = deposits[msg.sender];
        require(d.amount > 0, "No deposit");
        require(block.number >= d.blockNumber + REQUIRED_CONFIRMATIONS, "Await confirmations");
        uint256 amt = d.amount;
        d.amount = 0;
        payable(msg.sender).transfer(amt);
    }
}
