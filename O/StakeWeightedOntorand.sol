// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * Stake‑Weighted Ontorand
 * -----------------------------------------------------------
 * • Validators stake ETH (≥ MIN_STAKE) to join the candidate set.
 * • Owner (acting as governor) starts a round and selects a random
 *   committee (pseudo‑random via blockhash for demo purposes).
 * • In each round, vote weight equals the validator’s stake.
 * • Finality: a block hash is accepted when ≥ 2/3 of committee stake
 *   has voted for the same hash.
 *
 * FIX APPLIED:
 *   Added `constructor() Ownable(msg.sender)` so the OpenZeppelin
 *   `Ownable` base constructor receives its required `initialOwner`
 *   argument, removing the “No arguments passed to the base constructor”
 *   compilation error.
 */
contract StakeWeightedOntorand is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* ─────────────  Constants / State  ───────────── */
    uint256 public constant MIN_STAKE = 5 ether;

    EnumerableSet.AddressSet private validators;
    mapping(address => uint256) public stakeOf;

    struct Round {
        address[] committee;
        mapping(bytes32 => uint256) stakeVotes; // blockHash → total stake
        mapping(address => bool)     voted;
        bool     finalised;
        bytes32  finalBlock;
    }
    uint256 public currentRound;
    mapping(uint256 => Round) private rounds;

    /* ─────────────  Events  ───────────── */
    event Staked   (address indexed v, uint256 amount);
    event Unstaked (address indexed v, uint256 amount);
    event Committee(uint256 round, address[] committee);
    event VoteCast (uint256 round, address voter, uint256 weight, bytes32 hash);
    event Finalised(uint256 round, bytes32 hash);

    /* ─────────────  Constructor (FIX)  ───────────── */
    constructor() Ownable(msg.sender) {}

    /* ─────────────  Staking  ───────────── */
    receive() external payable { stake(); }

    function stake() public payable {
        require(msg.value >= MIN_STAKE, "stake too low");
        bool added = validators.add(msg.sender);
        stakeOf[msg.sender] += msg.value;
        if (added) emit Staked(msg.sender, msg.value);
    }

    function unstake(uint256 amount) external {
        require(stakeOf[msg.sender] >= amount, "insufficient stake");
        stakeOf[msg.sender] -= amount;
        if (stakeOf[msg.sender] == 0) validators.remove(msg.sender);
        payable(msg.sender).transfer(amount);
        emit Unstaked(msg.sender, amount);
    }

    /* ─────────────  Start a new round  ───────────── */
    function startRound(uint8 committeeSize) external onlyOwner {
        require(committeeSize > 0, "size zero");
        require(validators.length() >= committeeSize, "few validators");

        currentRound++;
        Round storage R = rounds[currentRound];

        uint256 seed = uint256(blockhash(block.number - 1));
        for (uint8 i = 0; i < committeeSize; i++) {
            address member = validators.at(
                uint256(keccak256(abi.encode(seed, i))) % validators.length()
            );
            R.committee.push(member);
        }

        emit Committee(currentRound, R.committee);
    }

    /* ─────────────  Voting  ───────────── */
    function vote(bytes32 blockHash) external {
        Round storage R = rounds[currentRound];
        require(!R.finalised, "round finalised");
        require(_isCommitteeMember(R.committee, msg.sender), "not committee");
        require(!R.voted[msg.sender], "already voted");

        uint256 weight = stakeOf[msg.sender];
        R.voted[msg.sender] = true;
        R.stakeVotes[blockHash] += weight;

        emit VoteCast(currentRound, msg.sender, weight, blockHash);

        uint256 totalStake;
        for (uint8 i = 0; i < R.committee.length; i++) {
            totalStake += stakeOf[R.committee[i]];
        }

        if (R.stakeVotes[blockHash] * 3 >= totalStake * 2) { // ≥ 2/3 stake
            R.finalised  = true;
            R.finalBlock = blockHash;
            emit Finalised(currentRound, blockHash);
        }
    }

    /* ─────────────  Views  ───────────── */
    function committeeOf(uint256 roundId) external view returns (address[] memory) {
        return rounds[roundId].committee;
    }

    function finalBlockOf(uint256 roundId) external view returns (bytes32) {
        require(rounds[roundId].finalised, "not final");
        return rounds[roundId].finalBlock;
    }

    /* ─────────────  Internal helper  ───────────── */
    function _isCommitteeMember(address[] storage arr, address a) private view returns (bool) {
        for (uint256 i; i < arr.length; i++) if (arr[i] == a) return true;
        return false;
    }
}
