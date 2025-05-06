// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SlotSuite
/// @notice Implements SlotAccessControl, SlotCommitReveal, and SlotLeaderElection
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// Helper to simulate Cardano slot (in tests, map to block.number or external oracle)
interface ISlotOracle {
    function currentSlot() external view returns (uint256);
}

/// 1) Slot-Based Access Control
contract SlotAccessControl is Base {
    ISlotOracle public slotOracle;
    uint256 public allowedSlot;
    uint256 private lastUsedSlot;

    constructor(address oracle, uint256 slot_) {
        slotOracle   = ISlotOracle(oracle);
        allowedSlot  = slot_;
    }

    // --- Attack: no slot check ⇒ anyone can call anytime or replay
    function privilegedActionInsecure() external {
        // no slot or monotonic check
        // do privileged work
    }

    // --- Defense: enforce slot >= allowedSlot && monotonic
    function privilegedActionSecure() external {
        uint256 s = slotOracle.currentSlot();
        require(s >= allowedSlot, "Too early for slot");
        require(s > lastUsedSlot,    "Slot replay");
        lastUsedSlot = s;
        // do privileged work
    }
}

/// 2) Slot Commit–Reveal
contract SlotCommitReveal is Base {
    ISlotOracle public slotOracle;
    struct Commit { bytes32 hash; uint256 commitSlot; bool revealed; }
    mapping(address => Commit) public commits;

    uint256 public commitWindow; // number of slots allowed for commit

    constructor(address oracle, uint256 window) {
        slotOracle    = ISlotOracle(oracle);
        commitWindow  = window;
    }

    // --- Attack: reveal immediately or commit outside window
    function commitInsecure(bytes32 h) external {
        commits[msg.sender] = Commit(h, slotOracle.currentSlot(), false);
    }
    function revealInsecure(string calldata secret) external view returns (bool) {
        Commit storage c = commits[msg.sender];
        // no slot ordering check
        return keccak256(abi.encodePacked(secret)) == c.hash;
    }

    // --- Defense: enforce commit slot range and reveal slot > commitSlot
    function commitSecure(bytes32 h) external {
        uint256 s = slotOracle.currentSlot();
        require(s <= commits[msg.sender].commitSlot + commitWindow || commits[msg.sender].commitSlot==0,
                "Commit window closed");
        commits[msg.sender] = Commit(h, s, false);
    }
    function revealSecure(string calldata secret) external {
        Commit storage c = commits[msg.sender];
        uint256 s = slotOracle.currentSlot();
        require(c.hash != 0,         "No commit");
        require(!c.revealed,         "Already revealed");
        require(s > c.commitSlot,    "Reveal in same slot");
        require(keccak256(abi.encodePacked(secret)) == c.hash,
                "Bad secret");
        c.revealed = true;
        // process secret...
    }
}

/// 3) Slot-Based Leader Election (VRF)
contract SlotLeaderElection is Base, ReentrancyGuard {
    ISlotOracle public slotOracle;
    mapping(address => mapping(uint256=>bool)) public used; // validator → slot → used

    event Elected(address validator, uint256 slot, bytes32 vrfOutput);

    constructor(address oracle) {
        slotOracle = ISlotOracle(oracle);
    }

    // --- Attack: reuse VRF proof across slots or forge without slot
    function electInsecure(bytes32 vrfOutput) external {
        uint256 s = slotOracle.currentSlot();
        // no slot binding ⇒ same vrfOutput works every slot
        emit Elected(msg.sender, s, vrfOutput);
    }

    // --- Defense: include slot in seed, track used, verify signature
    function electSecure(
        bytes32 vrfOutput,
        bytes calldata vrfProof,
        bytes32 publicKey
    ) external nonReentrant {
        uint256 s = slotOracle.currentSlot();
        require(!used[msg.sender][s], "Already elected this slot");
        // verify vrfProof correctness over seed = keccak256(abi.encodePacked(s, publicKey))
        bytes32 seed = keccak256(abi.encodePacked(s, publicKey));
        require(_verifyVRF(seed, vrfOutput, vrfProof, publicKey),
                "Invalid VRF proof");
        used[msg.sender][s] = true;
        emit Elected(msg.sender, s, vrfOutput);
    }

    // stub VRF verifier; in production integrate real on-chain VRF
    function _verifyVRF(
        bytes32 seed,
        bytes32 output,
        bytes calldata proof,
        bytes32 pubKey
    ) internal pure returns (bool) {
        // placeholder: assume always true
        seed; output; proof; pubKey;
        return true;
    }
}
