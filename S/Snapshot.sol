// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

abstract contract ReentrancyGuard {
    bool private _lock;
    modifier nonReentrant() {
        require(!_lock, "Reentrant");
        _lock = true;
        _;
        _lock = false;
    }
}

//////////////////////////////////////////////////////
// 1) ERC20 Balance Snapshot
//////////////////////////////////////////////////////
contract BalanceSnapshot is Base {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    // naive snapshot id
    uint256 public snapId;

    // insecure: just increments snapId, but stores nothing
    function snapshotInsecure() external onlyOwner returns (uint256) {
        return ++snapId;
    }

    // secure: record each account’s balance at snapshot
    struct Checkpoint { uint256 id; uint256 value; }
    mapping(address => Checkpoint[]) private _checkpoints;
    uint256 private _secureSnapId;

    function _writeCheckpoint(address acct, uint256 id) private {
        _checkpoints[acct].push(Checkpoint(id, balanceOf[acct]));
    }

    function snapshotSecure() external onlyOwner returns (uint256) {
        _secureSnapId++;
        // record for all holders: emit event for off-chain or iterate small set
        // here we record for msg.sender only as example:
        _writeCheckpoint(msg.sender, _secureSnapId);
        return _secureSnapId;
    }

    // insecure read returns current balance, not historical
    function balanceAtInsecure(address acct, uint256 /*id*/) external view returns (uint256) {
        return balanceOf[acct];
    }

    // secure read via binary search in checkpoints
    function balanceAtSecure(address acct, uint256 id) external view returns (uint256) {
        Checkpoint[] storage cps = _checkpoints[acct];
        if (cps.length == 0 || id < cps[0].id) return 0;
        // find last <= id
        for (uint i = cps.length; i > 0; i--) {
            if (cps[i-1].id <= id) return cps[i-1].value;
        }
        return 0;
    }

    // simple mint/burn to test
    function mint(address to, uint256 amt) external onlyOwner {
        balanceOf[to] += amt; totalSupply += amt;
    }
    function burn(address from, uint256 amt) external onlyOwner {
        balanceOf[from] -= amt; totalSupply -= amt;
    }
}

//////////////////////////////////////////////////////
// 2) Voting Power Snapshot
//////////////////////////////////////////////////////
contract VotingSnapshot is Base {
    mapping(address => uint256) public delegates;
    BalanceSnapshot public token;
    uint256 public safetyMargin = 2; // blocks

    constructor(address token_) { token = BalanceSnapshot(token_); }

    // insecure: just reads current voting power
    function getVotesInsecure(address acct, uint256 /*snapshotBlock*/) external view returns (uint256) {
        return token.balanceOf(acct);
    }

    // secure: reads prior votes at safe snapshot
    function getVotesSecure(address acct, uint256 snapshotBlock) external view returns (uint256) {
        require(snapshotBlock + safetyMargin < block.number, "Snapshot too recent");
        return token.balanceAtSecure(acct, snapshotBlock);
    }

    // mimic delegate: for testing only
    function delegate(address to) external {
        delegates[msg.sender] = to;
    }
}

//////////////////////////////////////////////////////
// 3) Airdrop Eligibility Snapshot
//////////////////////////////////////////////////////
contract AirdropSnapshot is Base, ReentrancyGuard {
    mapping(address => bool) public registered;
    address[] public holders;

    uint256 public airdropSnap;
    mapping(uint256 => mapping(address=>bool)) public claimed;

    // insecure: allow registration anytime, even after snapshot
    function registerInsecure() external {
        registered[msg.sender] = true;
        holders.push(msg.sender);
    }

    // secure: only before snapshot
    function registerSecure() external {
        require(airdropSnap == 0, "Registration closed");
        registered[msg.sender] = true;
        holders.push(msg.sender);
    }

    // take snapshot, freeze registrations
    function snapshotAirdrop() external onlyOwner {
        airdropSnap = block.number;
    }

    // insecure: any registered can claim multiple times
    function claimInsecure() external {
        require(registered[msg.sender], "Not registered");
        // send token or ETH...
    }

    // secure: one claim per snapshot, and only those registered at snapshot
    function claimSecure() external nonReentrant {
        require(airdropSnap != 0, "Snapshot not set");
        require(registered[msg.sender], "Not registered");
        require(!claimed[airdropSnap][msg.sender], "Already claimed");
        claimed[airdropSnap][msg.sender] = true;
        // send token or ETH...
    }
}
