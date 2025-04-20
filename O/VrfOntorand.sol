// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* ── OpenZeppelin / Chainlink imports ───────────────────────────────── */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/**
 * VrfOntorand – committee selection via Chainlink VRF
 * ---------------------------------------------------
 * • Validators self‑stake ETH. (MIN_STAKE default = 1 ETH)
 * • Owner triggers `selectCommittee`; random words decide members.
 * • The real Ontology VBFT uses BLS‑based VRF at node layer;
 *   this contract is an on‑chain demo using Chainlink VRF.
 *
 *  FIX APPLIED:
 *    constructor now calls `Ownable(msg.sender)` so the
 *    OpenZeppelin base constructor receives an `initialOwner`,
 *    eliminating “No arguments passed to the base constructor” error.
 */
contract VrfOntorand is VRFConsumerBaseV2, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* =========  Chainlink VRF parameters  ========= */
    VRFCoordinatorV2Interface public immutable COORDINATOR;
    bytes32 public immutable keyHash;
    uint64  public immutable subId;

    uint16  public confirmations = 3;
    uint32  public gasLimit      = 200_000;

    /* =========  Staking  ========= */
    uint256 public constant MIN_STAKE = 1 ether;
    EnumerableSet.AddressSet private validators;
    mapping(address => uint256) public stakeOf;

    /* =========  Round data  ========= */
    struct Round {
        address[] committee;
        bool      ready;
    }
    uint256 public round;
    mapping(uint256 => Round) public rounds;

    event Staked   (address indexed v, uint256 amount);
    event Unstaked (address indexed v, uint256 amount);
    event VRFRequested(uint256 indexed round, uint256 requestId);
    event Committee (uint256 indexed round, address[] members);

    /* =========  Constructor  ========= */
    constructor(
        address vrfCoordinator,
        uint64  _subId,
        bytes32 _keyHash
    )
        VRFConsumerBaseV2(vrfCoordinator)
        Ownable(msg.sender)                           // ← FIX
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        subId   = _subId;
        keyHash = _keyHash;
    }

    /* =========  Stake management  ========= */
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

    /* =========  Committee selection  ========= */
    function selectCommittee(uint8 size) external onlyOwner {
        require(size > 0,            "size zero");
        require(validators.length() >= size, "few validators");

        round++;
        uint256 reqId = COORDINATOR.requestRandomWords(
            keyHash,
            subId,
            confirmations,
            gasLimit,
            1 /* numWords */
        );
        // store desired size in high bits of round id (cheap)
        rounds[round].committee = new address[](size);
        emit VRFRequested(round, reqId);
    }

    /* =========  VRF callback  ========= */
    function fulfillRandomWords(uint256, uint256[] memory words) internal override {
        uint256 rand = words[0];
        Round storage R = rounds[round];

        uint256 vCount = validators.length();
        uint8 size = uint8(R.committee.length);

        for (uint8 i = 0; i < size; i++) {
            uint256 idx = uint256(keccak256(abi.encode(rand, i))) % vCount;
            address member = validators.at(idx);
            R.committee[i] = member;
        }
        R.ready = true;
        emit Committee(round, R.committee);
    }

    /* =========  View helper ========= */
    function currentCommittee() external view returns (address[] memory) {
        require(rounds[round].ready, "committee not ready");
        return rounds[round].committee;
    }
}
