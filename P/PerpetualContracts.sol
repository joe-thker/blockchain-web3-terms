// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title PermissionlessMarketCreationSuite.sol
/// @notice On‐chain analogues of “Permissionless Market Creation” patterns:
///   Types: SpotMarket, PredictionMarket, Auction, DEX  
///   AttackTypes: FakeMarket, FrontRunning, SybilCreation, LiquidityDrain  
///   DefenseTypes: AccessControl, RateLimit, ReputationSystem, MultiSig, SignatureValidation

enum PMCType                { SpotMarket, PredictionMarket, Auction, DEX }
enum PMCAttackType          { FakeMarket, FrontRunning, SybilCreation, LiquidityDrain }
enum PMCDefenseType         { AccessControl, RateLimit, ReputationSystem, MultiSig, SignatureValidation }

error PMC__NotAuthorized();
error PMC__TooManyRequests();
error PMC__InsufficientReputation();
error PMC__InvalidSignature();
error PMC__AlreadyApproved();

////////////////////////////////////////////////////////////////////////////////
// 1) VULNERABLE MARKET CREATOR
//    • ❌ no checks: anyone may create → FakeMarket
////////////////////////////////////////////////////////////////////////////////
contract PMCVuln {
    struct Market { address creator; string name; }
    Market[] public markets;

    event MarketCreated(
        address indexed who,
        uint256           marketId,
        PMCType           mtype,
        PMCAttackType     attack
    );

    function createMarket(string calldata name, PMCType mtype) external {
        markets.push(Market(msg.sender, name));
        emit MarketCreated(msg.sender, markets.length - 1, mtype, PMCAttackType.FakeMarket);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 2) ATTACK STUB
//    • simulates front‐running, sybil creation, liquidity drain
////////////////////////////////////////////////////////////////////////////////
contract Attack_PMC {
    PMCVuln public target;
    uint256 public lastId;
    string  public lastName;
    PMCType public lastType;

    constructor(PMCVuln _t) { target = _t; }

    function fake(string calldata name) external {
        target.createMarket(name, PMCType.SpotMarket);
        lastId   = target.marketsLength() - 1;
        lastName = name;
        lastType = PMCType.SpotMarket;
    }

    function frontRun(string calldata name) external {
        target.createMarket(name, PMCType.PredictionMarket);
    }

    function sybil(uint count) external {
        for (uint i = 0; i < count; i++) {
            target.createMarket("Sybil", PMCType.Auction);
        }
    }

    function drain(string calldata name) external {
        target.createMarket(name, PMCType.DEX);
    }

    function replay() external {
        target.createMarket(lastName, lastType);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 3) SAFE WITH ACCESS CONTROL
//    • ✅ Defense: AccessControl – only owner may create
////////////////////////////////////////////////////////////////////////////////
contract PMCSafeAccess {
    struct Market { address creator; string name; }
    Market[] public markets;
    address public owner;

    event MarketCreated(
        address indexed who,
        uint256           marketId,
        PMCType           mtype,
        PMCDefenseType    defense
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert PMC__NotAuthorized();
        _;
    }

    function createMarket(string calldata name, PMCType mtype) external onlyOwner {
        markets.push(Market(msg.sender, name));
        emit MarketCreated(msg.sender, markets.length - 1, mtype, PMCDefenseType.AccessControl);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 4) SAFE WITH REPUTATION & RATE LIMIT
//    • ✅ Defense: ReputationSystem – require reputation ✔  
//               RateLimit        – cap creations per block
////////////////////////////////////////////////////////////////////////////////
contract PMCSafeReputation {
    struct Market { address creator; string name; }
    Market[] public markets;
    mapping(address => uint256) public reputation;
    mapping(address => uint256) public lastBlock;
    mapping(address => uint256) public creationsInBlock;
    uint256 public constant MIN_REP = 10;
    uint256 public constant MAX_PER_BLOCK = 2;

    event MarketCreated(
        address indexed who,
        uint256           marketId,
        PMCType           mtype,
        PMCDefenseType    defense
    );

    error PMC__InsufficientReputation();
    error PMC__TooManyRequests();

    function awardReputation(address user, uint256 pts) external {
        // stub: admin
        reputation[user] += pts;
    }

    function createMarket(string calldata name, PMCType mtype) external {
        if (reputation[msg.sender] < MIN_REP) revert PMC__InsufficientReputation();

        if (block.number != lastBlock[msg.sender]) {
            lastBlock[msg.sender]       = block.number;
            creationsInBlock[msg.sender] = 0;
        }
        creationsInBlock[msg.sender]++;
        if (creationsInBlock[msg.sender] > MAX_PER_BLOCK) revert PMC__TooManyRequests();

        markets.push(Market(msg.sender, name));
        emit MarketCreated(msg.sender, markets.length - 1, mtype, PMCDefenseType.ReputationSystem);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 5) SAFE ADVANCED WITH MULTISIG & SIGNATURE VALIDATION
//    • ✅ Defense: SignatureValidation – off‐chain admin signature ✔  
//               MultiSig             – require N approvals ★
////////////////////////////////////////////////////////////////////////////////
contract PMCSafeAdvanced {
    struct Market { address creator; string name; bool executed; }
    Market[] public markets;

    address[] public admins;
    uint256 public required;
    mapping(uint256 => mapping(address => bool)) public approved;
    mapping(uint256 => uint256) public approvalCount;
    address public signer;

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string            name,
        PMCType           mtype,
        PMCDefenseType    defense
    );
    event Approved(
        uint256 indexed proposalId,
        address indexed admin,
        uint256           count,
        PMCDefenseType    defense
    );
    event MarketCreated(
        uint256 indexed proposalId,
        uint256           marketId,
        PMCType           mtype,
        PMCDefenseType    defense
    );

    error PMC__NotAuthorized();
    error PMC__AlreadyApproved();
    error PMC__InsufficientApprovals();
    error PMC__InvalidSignature();

    struct Proposal {
        address proposer;
        string  name;
        PMCType mtype;
        bool    executed;
    }
    Proposal[] public proposals;

    constructor(address[] memory _admins, uint256 _required, address _signer) {
        require(_required <= _admins.length, "invalid threshold");
        admins = _admins;
        required = _required;
        signer = _signer;
    }

    function proposeMarket(
        string calldata name,
        PMCType mtype,
        bytes calldata sig
    ) external returns (uint256) {
        // verify admin signature over (msg.sender||name||mtype)
        bytes32 h = keccak256(abi.encodePacked(msg.sender, name, mtype));
        bytes32 eth = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(sig,(uint8,bytes32,bytes32));
        if (ecrecover(eth, v, r, s) != signer) revert PMC__InvalidSignature();

        proposals.push(Proposal(msg.sender, name, mtype, false));
        uint256 pid = proposals.length - 1;
        emit ProposalCreated(pid, msg.sender, name, mtype, PMCDefenseType.SignatureValidation);
        return pid;
    }

    function approveProposal(uint256 proposalId) external {
        bool isAdmin;
        for (uint i; i < admins.length; i++) {
            if (admins[i] == msg.sender) { isAdmin = true; break; }
        }
        if (!isAdmin) revert PMC__NotAuthorized();
        if (approved[proposalId][msg.sender]) revert PMC__AlreadyApproved();
        approved[proposalId][msg.sender] = true;
        approvalCount[proposalId]++;
        emit Approved(proposalId, msg.sender, approvalCount[proposalId], PMCDefenseType.MultiSig);

        if (approvalCount[proposalId] >= required && !proposals[proposalId].executed) {
            proposals[proposalId].executed = true;
            Market memory m = Market(proposals[proposalId].proposer, proposals[proposalId].name, true);
            markets.push(m);
            emit MarketCreated(proposalId, markets.length - 1, proposals[proposalId].mtype, PMCDefenseType.MultiSig);
        }
    }
}
