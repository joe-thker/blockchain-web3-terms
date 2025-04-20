// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * OntorandLite – equal‑weight committee demo
 * ------------------------------------------
 * The previous version used the shorthand
 *    for (address m : R.committee) { ... }
 * which is **not valid** Solidity syntax and triggered
 * `ParserError: Expected ';' but got ':'`.
 *
 * This fixed version replaces that syntax with a classic
 * index‑based loop.
 */
contract OntorandLite is AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* --------- roles & constants --------- */
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    uint256 public constant MIN_STAKE = 10 ether;

    /* --------- validator stake --------- */
    EnumerableSet.AddressSet private _validators;
    mapping(address => uint256) public stakeOf;

    /* --------- round state --------- */
    struct Round {
        address[] committee;
        mapping(bytes32 => uint256) votes; // equal weight
        mapping(address => bool)    voted;
        bool     finalised;
        bytes32  finalBlock;
    }
    uint256 public currentRound;
    mapping(uint256 => Round) private _rounds;

    /* --------- events --------- */
    event Staked(address v, uint256 amt);
    event Unstaked(address v, uint256 amt);
    event Committee(uint256 round, address[] members);
    event Voted(uint256 round, address voter, bytes32 blk);
    event Finalised(uint256 round, bytes32 blk);

    /* --------- constructor --------- */
    constructor(address governor) {
        _grantRole(GOVERNOR_ROLE, governor);
    }

    /* --------- staking --------- */
    receive() external payable { stake(); }

    function stake() public payable {
        require(msg.value >= MIN_STAKE, "low stake");
        bool added = _validators.add(msg.sender);
        stakeOf[msg.sender] += msg.value;
        if (added) emit Staked(msg.sender, msg.value);
    }

    function unstake(uint256 amt) external {
        require(stakeOf[msg.sender] >= amt, "not enough");
        stakeOf[msg.sender] -= amt;
        if (stakeOf[msg.sender] == 0) _validators.remove(msg.sender);
        payable(msg.sender).transfer(amt);
        emit Unstaked(msg.sender, amt);
    }

    /* --------- start new round --------- */
    function startRound(uint8 committeeSize) external onlyRole(GOVERNOR_ROLE) {
        require(committeeSize > 0, "size 0");
        require(_validators.length() >= committeeSize, "few validators");

        currentRound++;
        Round storage R = _rounds[currentRound];

        uint256 seed = uint256(blockhash(block.number - 1));
        uint256 pool = _validators.length();

        // sample without replacement
        for (uint8 i = 0; i < committeeSize; i++) {
            uint256 idx = uint256(keccak256(abi.encode(seed, i))) % pool;
            address member = _validators.at(idx);

            // temporarily remove to avoid duplicates
            _validators.remove(member);
            pool--;

            R.committee.push(member);
        }

        /* ---------- RE‑ADD members (fixed loop syntax) ---------- */
        for (uint256 i = 0; i < R.committee.length; i++) {
            _validators.add(R.committee[i]);
        }

        emit Committee(currentRound, R.committee);
    }

    /* --------- voting --------- */
    function vote(bytes32 blkHash) external {
        Round storage R = _rounds[currentRound];
        require(!R.finalised, "round done");
        require(_isCommittee(R.committee, msg.sender), "not committee");
        require(!R.voted[msg.sender], "voted");

        R.voted[msg.sender] = true;
        R.votes[blkHash] += 1;
        emit Voted(currentRound, msg.sender, blkHash);

        uint256 needed = (2 * R.committee.length) / 3 + 1;
        if (R.votes[blkHash] >= needed) {
            R.finalised  = true;
            R.finalBlock = blkHash;
            emit Finalised(currentRound, blkHash);
        }
    }

    /* --------- helpers --------- */
    function _isCommittee(address[] storage list, address a) private view returns (bool) {
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == a) return true;
        }
        return false;
    }

    function committeeOf(uint256 rnd) external view returns (address[] memory) {
        return _rounds[rnd].committee;
    }

    function finalBlock(uint256 rnd) external view returns (bytes32) {
        require(_rounds[rnd].finalised, "not final");
        return _rounds[rnd].finalBlock;
    }
}
