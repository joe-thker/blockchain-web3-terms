// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/* -----------------------------------------------------
 * 1) DumpBasic
 * -----------------------------------------------------
 * A straightforward mintable/burnable ERC20 named "DumpBasic."
 * The contract owner can mint and burn tokens.
 */
contract DumpBasic is ERC20, Ownable, ReentrancyGuard {
    constructor(uint256 initialSupply) ERC20("DumpBasic", "DUMPBASIC") Ownable(msg.sender) {
        // Mint initial supply to the deployer
        _mint(msg.sender, initialSupply);
    }

    /// @notice Mints new tokens to `to`. Only the owner can call.
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Mint amount must be > 0");
        _mint(to, amount);
    }

    /// @notice Burns `amount` tokens from `from`. Only the owner can call.
    function burn(address from, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Burn amount must be > 0");
        _burn(from, amount);
    }
}

/* -----------------------------------------------------
 * 2) DumpTimelock
 * -----------------------------------------------------
 * An ERC20 named "DumpTimelock" that includes a timelocked deposit approach:
 * Users deposit tokens for a specific lock duration, then can only withdraw (“dump”) after time passes.
 * The contract also features a simple mint/burn by the owner if needed.
 */
contract DumpTimelock is ERC20, Ownable, ReentrancyGuard {
    // Mapping user => locked token info
    struct LockInfo {
        uint256 amount;
        uint256 unlockTimestamp;
    }

    mapping(address => LockInfo) public locks;
    uint256 public defaultLockDuration; // e.g. 7 days

    constructor(uint256 initialSupply, uint256 _defaultLockDuration)
        ERC20("DumpTimelock", "DUMPTIME")
        Ownable(msg.sender)
    {
        // Mint initial supply to the deployer
        _mint(msg.sender, initialSupply);
        defaultLockDuration = _defaultLockDuration;
    }

    /// @notice Adjusts the default lock duration. Only owner can call.
    function setLockDuration(uint256 newDuration) external onlyOwner {
        defaultLockDuration = newDuration;
    }

    /// @notice Users deposit their tokens into a timelock. Must have approved this contract for `amount`.
    function depositLock(uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit amount must be > 0");
        // Transfer tokens from user to contract
        bool success = transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");
        // Update lock info
        LockInfo storage li = locks[msg.sender];
        li.amount += amount;
        // Reset/Update unlock time to now + defaultLockDuration
        li.unlockTimestamp = block.timestamp + defaultLockDuration;
    }

    /// @notice Users can withdraw (“dump”) their locked tokens after the unlock time.
    function withdrawLock() external nonReentrant {
        LockInfo storage li = locks[msg.sender];
        require(li.amount > 0, "No locked tokens");
        require(block.timestamp >= li.unlockTimestamp, "Tokens still locked");
        
        uint256 amt = li.amount;
        li.amount = 0;
        // Transfer from contract back to user
        _transfer(address(this), msg.sender, amt);
    }

    /// @notice Mints new tokens to a specified address. Only owner can call.
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Mint must be > 0");
        _mint(to, amount);
    }

    /// @notice Burns tokens from a specified address. Only owner can call.
    function burn(address from, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Burn must be > 0");
        _burn(from, amount);
    }
}

/* -----------------------------------------------------
 * 3) DumpScheduled
 * -----------------------------------------------------
 * An ERC20 named "DumpScheduled." The owner sets up scheduled “release times” 
 * at which certain amounts can be minted. The owner can “dump” tokens on those 
 * schedules, demonstrating a time-based release approach.
 */
contract DumpScheduled is ERC20, Ownable, ReentrancyGuard {
    // Each schedule: a time and an amount that can be minted at or after that time.
    struct ReleaseSchedule {
        uint256 releaseTime;
        uint256 amount;
        bool released;
    }

    ReleaseSchedule[] public schedules;

    constructor(uint256 initialSupply) ERC20("DumpScheduled", "DUMPSCHED") Ownable(msg.sender) {
        // Mint initial supply to the deployer
        _mint(msg.sender, initialSupply);
    }

    /// @notice Add a new release schedule for future tokens.
    /// @param releaseTime The timestamp after which the scheduled tokens can be minted.
    /// @param amount The number of tokens to be minted at release.
    function addSchedule(uint256 releaseTime, uint256 amount) external onlyOwner {
        require(releaseTime > block.timestamp, "Release time must be in future");
        require(amount > 0, "Release amount must be > 0");
        schedules.push(ReleaseSchedule({
            releaseTime: releaseTime,
            amount: amount,
            released: false
        }));
    }

    /// @notice Release tokens for a specific schedule if time has arrived, minting them to the owner (or a designated address).
    /// For demonstration, we mint to the owner. You can adapt to another recipient.
    /// @param scheduleIndex The index in the schedules array.
    function releaseTokens(uint256 scheduleIndex) external onlyOwner nonReentrant {
        require(scheduleIndex < schedules.length, "Invalid schedule index");
        ReleaseSchedule storage rs = schedules[scheduleIndex];
        require(!rs.released, "Already released");
        require(block.timestamp >= rs.releaseTime, "Release time not reached");

        rs.released = true;
        _mint(msg.sender, rs.amount);
    }

    /// @notice Mints new tokens outside of the scheduled approach, if needed. 
    /// Potentially for dev or emergency. Only owner can call.
    /// @param to The address to receive minted tokens.
    /// @param amount The number of tokens to mint.
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Mint must be > 0");
        _mint(to, amount);
    }

    /// @notice Burns tokens from a specified address. Only owner can call.
    /// @param from The address from which tokens are burned.
    /// @param amount The amount to burn.
    function burn(address from, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Burn must be > 0");
        _burn(from, amount);
    }
}

/* -----------------------------------------------------
 * Explanation
 * -----------------------------------------------------
 * These 3 "Dump" types illustrate different token designs:
 * 1) DumpBasic: simple mint/burn ERC20.
 * 2) DumpTimelock: deposit-based timelock approach to "dump" after time.
 * 3) DumpScheduled: time-based minted releases ("scheduled dumps").
 * 
 * All are dynamic, with owner-based supply control, and "optimized" using minimal logic 
 * plus standard OpenZeppelin security patterns (Ownable + ReentrancyGuard).
 * ----------------------------------------------------- */
