// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title PermissionedLedgerSuite.sol
/// @notice On‐chain analogues of “Permissioned Ledger” governance patterns:
///   Types: Consortium, Private, Hybrid, PublicAccess  
///   AttackTypes: UnauthorizedWrite, DoubleSpend, ReplayAttack, Fork  
///   DefenseTypes: AccessControl, MultiSig, AuditLogging, RateLimit, SignatureValidation

enum PermissionedLedgerType    { Consortium, Private, Hybrid, PublicAccess }
enum PLAttackType              { UnauthorizedWrite, DoubleSpend, ReplayAttack, Fork }
enum PLDefenseType             { AccessControl, MultiSig, AuditLogging, RateLimit, SignatureValidation }

error PL__NotAuthorized();
error PL__TooManyRequests();
error PL__InvalidSignature();
error PL__AlreadyApproved();
error PL__InsufficientApprovals();

////////////////////////////////////////////////////////////////////////////////
// 1) VULNERABLE LEDGER
//    • ❌ no permissions: anyone may record transactions → UnauthorizedWrite
////////////////////////////////////////////////////////////////////////////////
contract PermissionedLedgerVuln {
    struct Transaction { address from; address to; uint256 amount; }
    Transaction[] public ledger;

    event TransactionRecorded(
        address indexed who,
        uint256           txIndex,
        PermissionedLedgerType ltype,
        PLAttackType      attack
    );

    function recordTransaction(
        address to,
        uint256 amount,
        PermissionedLedgerType ltype
    ) external {
        ledger.push(Transaction(msg.sender, to, amount));
        emit TransactionRecorded(msg.sender, ledger.length - 1, ltype, PLAttackType.UnauthorizedWrite);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 2) ATTACK STUB
//    • simulates unauthorized writes, double‐spend & replay
////////////////////////////////////////////////////////////////////////////////
contract Attack_PermissionedLedger {
    PermissionedLedgerVuln public target;
    uint256 public lastIndex;
    address public lastTo;
    uint256 public lastAmount;

    constructor(PermissionedLedgerVuln _t) {
        target = _t;
    }

    function forge(address to, uint256 amount) external {
        target.recordTransaction(to, amount, PermissionedLedgerType.Consortium);
        lastIndex  = target.ledgerLength() - 1;
        lastTo     = to;
        lastAmount = amount;
    }

    function doubleSpend(address to, uint256 amount) external {
        // attacker submits two transactions with same funds
        target.recordTransaction(to, amount, PermissionedLedgerType.Private);
        target.recordTransaction(to, amount, PermissionedLedgerType.Private);
    }

    function replayLast() external {
        target.recordTransaction(lastTo, lastAmount, PermissionedLedgerType.Hybrid);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 3) SAFE WITH ACCESS CONTROL
//    • ✅ Defense: AccessControl – only owner may record
////////////////////////////////////////////////////////////////////////////////
contract PermissionedLedgerSafeAccess {
    struct Transaction { address from; address to; uint256 amount; }
    Transaction[] public ledger;
    address public owner;

    event TransactionRecorded(
        address indexed who,
        uint256           txIndex,
        PermissionedLedgerType ltype,
        PLDefenseType     defense
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert PL__NotAuthorized();
        _;
    }

    function recordTransaction(
        address to,
        uint256 amount,
        PermissionedLedgerType ltype
    ) external onlyOwner {
        ledger.push(Transaction(msg.sender, to, amount));
        emit TransactionRecorded(msg.sender, ledger.length - 1, ltype, PLDefenseType.AccessControl);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 4) SAFE WITH MULTI‐SIGNATURE APPROVAL
//    • ✅ Defense: MultiSig – require N approvals before final record
////////////////////////////////////////////////////////////////////////////////
contract PermissionedLedgerSafeMultiSig {
    struct Transaction { address from; address to; uint256 amount; bool executed; }
    Transaction[] public proposals;
    mapping(uint256 => mapping(address => bool)) public approved;
    mapping(address => bool) public isSigner;
    address[] public signers;
    uint256 public required;

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        PermissionedLedgerType ltype,
        PLDefenseType     defense
    );
    event Approved(
        uint256 indexed proposalId,
        address indexed signer,
        uint256           count,
        PLDefenseType     defense
    );
    event Executed(
        uint256 indexed proposalId,
        PLDefenseType     defense
    );

    error PL__AlreadyApproved();
    error PL__InsufficientApprovals();

    constructor(address[] memory _signers, uint256 _required) {
        require(_required <= _signers.length, "invalid required count");
        signers = _signers;
        required = _required;
        for (uint i; i < _signers.length; i++) {
            isSigner[_signers[i]] = true;
        }
    }

    function propose(
        address to,
        uint256 amount,
        PermissionedLedgerType ltype
    ) external returns (uint256) {
        require(isSigner[msg.sender], "not a signer");
        proposals.push(Transaction(msg.sender, to, amount, false));
        uint256 pid = proposals.length - 1;
        emit ProposalCreated(pid, msg.sender, ltype, PLDefenseType.MultiSig);
        return pid;
    }

    function approve(uint256 proposalId) external {
        require(isSigner[msg.sender], "not a signer");
        require(!approved[proposalId][msg.sender], "already approved");
        approved[proposalId][msg.sender] = true;

        // count
        uint256 count;
        for (uint i; i < signers.length; i++) {
            if (approved[proposalId][signers[i]]) count++;
        }
        emit Approved(proposalId, msg.sender, count, PLDefenseType.MultiSig);

        if (count >= required && !proposals[proposalId].executed) {
            proposals[proposalId].executed = true;
            ledger.push(proposals[proposalId]);
            emit Executed(proposalId, PLDefenseType.MultiSig);
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
// 5) SAFE ADVANCED WITH SIGNATURE VALIDATION & RATE LIMIT
//    • ✅ Defense: SignatureValidation – require admin signature  
//               RateLimit           – cap records per block
////////////////////////////////////////////////////////////////////////////////
contract PermissionedLedgerSafeAdvanced {
    struct Transaction { address from; address to; uint256 amount; }
    Transaction[] public ledger;
    address public signer;
    mapping(address => uint256) public lastBlock;
    mapping(address => uint256) public callsInBlock;
    uint256 public constant MAX_CALLS = 3;

    event TransactionRecorded(
        address indexed who,
        uint256           txIndex,
        PermissionedLedgerType ltype,
        PLDefenseType     defense
    );

    error PL__TooManyRequests();
    error PL__InvalidSignature();

    constructor(address _signer) {
        signer = _signer;
    }

    function recordTransaction(
        address to,
        uint256 amount,
        PermissionedLedgerType ltype,
        bytes calldata sig
    ) external {
        // rate limit
        if (block.number != lastBlock[msg.sender]) {
            lastBlock[msg.sender]    = block.number;
            callsInBlock[msg.sender] = 0;
        }
        callsInBlock[msg.sender]++;
        if (callsInBlock[msg.sender] > MAX_CALLS) revert PL__TooManyRequests();

        // verify signature over (to||amount||ltype)
        bytes32 h = keccak256(abi.encodePacked(to, amount, ltype));
        bytes32 eth = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(sig,(uint8,bytes32,bytes32));
        if (ecrecover(eth, v, r, s) != signer) revert PL__InvalidSignature();

        ledger.push(Transaction(msg.sender, to, amount));
        emit TransactionRecorded(msg.sender, ledger.length - 1, ltype, PLDefenseType.SignatureValidation);
    }
}
