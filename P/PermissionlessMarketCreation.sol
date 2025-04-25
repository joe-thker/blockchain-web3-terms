// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title PermissionlessSuite.sol
/// @notice On‐chain analogues of “Permissionless” system patterns:
///   Types: ReadOnly, WriteOnly, OpenGovernance, OpenRegistration  
///   AttackTypes: Spam, UnauthorizedWrite, FrontRunning, DenialOfService  
///   DefenseTypes: AccessControl, RateLimit, SignatureValidation, MultiSig

enum PermissionlessType           { ReadOnly, WriteOnly, OpenGovernance, OpenRegistration }
enum PermissionlessAttackType     { Spam, UnauthorizedWrite, FrontRunning, DenialOfService }
enum PermissionlessDefenseType    { AccessControl, RateLimit, SignatureValidation, MultiSig }

error PLS__NotAuthorized();
error PLS__TooManyRequests();
error PLS__InvalidSignature();
error PLS__AlreadyApproved();

////////////////////////////////////////////////////////////////////////////////
// 1) VULNERABLE PERMISSIONLESS CONTRACT
//    • ❌ fully open: anyone may call any function → UnauthorizedWrite, Spam
////////////////////////////////////////////////////////////////////////////////
contract PermissionlessVuln {
    string public data;
    event DataWritten(
        address indexed who,
        string            newValue,
        PermissionlessType ptype,
        PermissionlessAttackType attack
    );

    function write(string calldata newValue, PermissionlessType ptype) external {
        data = newValue;
        emit DataWritten(msg.sender, newValue, ptype, PermissionlessAttackType.UnauthorizedWrite);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 2) ATTACK STUB
//    • simulates spam, front‐running, DOS via repeated writes
////////////////////////////////////////////////////////////////////////////////
contract Attack_Permissionless {
    PermissionlessVuln public target;
    string public lastValue;
    PermissionlessType public lastType;

    constructor(PermissionlessVuln _t) {
        target = _t;
    }

    function spam(string calldata v, uint count) external {
        for (uint i = 0; i < count; i++) {
            target.write(v, PermissionlessType.WriteOnly);
        }
    }

    function frontRun(string calldata v) external {
        // attacker preempts legitimate write
        target.write(v, PermissionlessType.WriteOnly);
        lastValue = v;
        lastType  = PermissionlessType.WriteOnly;
    }

    function replay() external {
        target.write(lastValue, lastType);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 3) SAFE WITH ACCESS CONTROL
//    • ✅ Defense: AccessControl – only owner may write
////////////////////////////////////////////////////////////////////////////////
contract PermissionlessSafeAccess {
    string public data;
    address public owner;

    event DataWritten(
        address indexed who,
        string            newValue,
        PermissionlessType ptype,
        PermissionlessDefenseType defense
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert PLS__NotAuthorized();
        _;
    }

    function write(string calldata newValue, PermissionlessType ptype) external onlyOwner {
        data = newValue;
        emit DataWritten(msg.sender, newValue, ptype, PermissionlessDefenseType.AccessControl);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 4) SAFE WITH RATE LIMITING
//    • ✅ Defense: RateLimit – cap writes per block
////////////////////////////////////////////////////////////////////////////////
contract PermissionlessSafeRateLimit {
    string public data;
    mapping(address => uint256) public lastBlock;
    mapping(address => uint256) public writesInBlock;
    uint256 public constant MAX_WRITES = 3;

    event DataWritten(
        address indexed who,
        string            newValue,
        PermissionlessType ptype,
        PermissionlessDefenseType defense
    );

    error PLS__TooManyRequests();

    function write(string calldata newValue, PermissionlessType ptype) external {
        if (block.number != lastBlock[msg.sender]) {
            lastBlock[msg.sender]    = block.number;
            writesInBlock[msg.sender] = 0;
        }
        writesInBlock[msg.sender]++;
        if (writesInBlock[msg.sender] > MAX_WRITES) revert PLS__TooManyRequests();
        data = newValue;
        emit DataWritten(msg.sender, newValue, ptype, PermissionlessDefenseType.RateLimit);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 5) SAFE ADVANCED WITH SIGNATURE VALIDATION & MULTISIG
//    • ✅ Defense: SignatureValidation – require owner’s off‐chain signature  
//               MultiSig             – require N admin approvals
////////////////////////////////////////////////////////////////////////////////
contract PermissionlessSafeAdvanced {
    string public data;
    address public signer;
    mapping(uint256 => mapping(address => bool)) public approved;
    mapping(uint256 => uint256) public approvalCount;
    uint256 public proposalCount;
    uint256 public constant REQUIRED = 2;
    address[] public admins;

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string            value,
        PermissionlessDefenseType defense
    );
    event Approved(
        uint256 indexed proposalId,
        address indexed admin,
        uint256           count,
        PermissionlessDefenseType defense
    );
    event Executed(
        uint256 indexed proposalId,
        string            value,
        PermissionlessDefenseType defense
    );

    error PLS__InvalidSignature();
    error PLS__AlreadyApproved();
    error PLS__InsufficientApprovals();

    struct Proposal { string value; bool executed; }

    mapping(uint256 => Proposal) public proposals;

    constructor(address[] memory _admins, address _signer) {
        require(_admins.length >= REQUIRED, "not enough admins");
        admins = _admins;
        for (uint i; i < _admins.length; i++) {
            approved[proposalCount][_admins[i]] = false;
        }
        signer = _signer;
    }

    function propose(
        string calldata value,
        bytes calldata sig
    ) external returns (uint256) {
        // verify off‐chain signature over value
        bytes32 h = keccak256(abi.encodePacked(value));
        bytes32 eth = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(sig,(uint8,bytes32,bytes32));
        if (ecrecover(eth, v, r, s) != signer) revert PLS__InvalidSignature();

        uint256 pid = proposalCount++;
        proposals[pid] = Proposal(value, false);
        emit ProposalCreated(pid, msg.sender, value, PermissionlessDefenseType.SignatureValidation);
        return pid;
    }

    function approve(uint256 proposalId) external {
        bool isAdmin = false;
        for (uint i; i < admins.length; i++) {
            if (admins[i] == msg.sender) {
                isAdmin = true;
                break;
            }
        }
        if (!isAdmin) revert PLS__NotAuthorized();
        if (approved[proposalId][msg.sender]) revert PLS__AlreadyApproved();
        approved[proposalId][msg.sender] = true;
        approvalCount[proposalId]++;
        emit Approved(proposalId, msg.sender, approvalCount[proposalId], PermissionlessDefenseType.MultiSig);

        if (approvalCount[proposalId] >= REQUIRED && !proposals[proposalId].executed) {
            proposals[proposalId].executed = true;
            data = proposals[proposalId].value;
            emit Executed(proposalId, data, PermissionlessDefenseType.MultiSig);
        }
    }
}
