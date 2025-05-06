// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Base {
    address public owner;
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
    constructor() { owner = msg.sender; }
}

abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() { require(!_locked, "Reentrant"); _locked = true; _; _locked = false; }
}

/// 1) Validator Double-Signing Slash
contract DoubleSignSlasher is Base, ReentrancyGuard {
    mapping(address => bool) public slashed;
    uint256 public slashingReward = 1 ether;

    // --- Attack: slash without valid proof, allow replay
    function slashInsecure(address violator) external nonReentrant {
        // no proof required
        require(!slashed[violator], "Already slashed");
        slashed[violator] = true;
        payable(msg.sender).transfer(slashingReward);
    }

    // --- Defense: require two conflicting signatures + prevent replay
    function slashSecure(
        address violator,
        bytes calldata sig1, bytes calldata msg1,
        bytes calldata sig2, bytes calldata msg2
    ) external nonReentrant {
        require(!slashed[violator], "Already slashed");
        // verify both signatures from violator
        require(recover(keccak256(msg1), sig1) == violator, "Bad sig1");
        require(recover(keccak256(msg2), sig2) == violator, "Bad sig2");
        // ensure messages conflict (e.g. different epoch)
        require(keccak256(msg1) != keccak256(msg2), "Not conflicting");
        slashed[violator] = true;
        payable(msg.sender).transfer(slashingReward);
    }

    function recover(bytes32 h, bytes calldata sig) internal pure returns(address) {
        bytes32 eth = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(sig, (bytes32,bytes32,uint8));
        return ecrecover(eth, v, r, s);
    }

    receive() external payable {}
}

/// 2) Uptime/Fail-to-Sign Slash
contract UptimeSlasher is Base {
    mapping(address => mapping(uint256=>bool)) public slashedInWindow;
    address public slasher;
    uint256 public windowSize = 1024; // blocks

    modifier onlySlasher() { require(msg.sender == slasher, "Not slasher"); _; }
    constructor(address _slasher) { slasher = _slasher; }

    // --- Attack: slash anytime or multiple times
    function slashInsecure(address v, uint256 window) external {
        // no window bounds, no role check
        slashedInWindow[v][window] = true;
    }

    // --- Defense: enforce window bounds + single slash + role
    function slashSecure(address v, uint256 window) external onlySlasher {
        require(block.number >= window * windowSize, "Window not ended");
        require(!slashedInWindow[v][window], "Already slashed");
        slashedInWindow[v][window] = true;
    }
}

/// 3) Balance-Based Jail & Slash
contract JailSlash is Base {
    struct Info { uint256 stake; uint256 jailEnd; bool active; }
    mapping(address => Info) public validators;
    uint256 public minStake = 10 ether;
    uint256 public maxSlashBP = 1000; // 10%

    // --- Attack: slash below min stake, bypass jail, withdraw jailed stake
    function slashInsecure(address v, uint256 amount) external {
        // no stake check, no jail, just deduct
        validators[v].stake -= amount;
    }

    // --- Defense: enforce stake bounds, jail, cap slash
    function slashSecure(address v, uint256 slashBP, uint256 jailDuration) external onlyOwner {
        Info storage i = validators[v];
        require(i.stake >= minStake, "Below min stake");
        require(slashBP <= maxSlashBP, "Slash too high");
        uint256 amt = (i.stake * slashBP) / 10000;
        i.stake -= amt;
        i.jailEnd = block.timestamp + jailDuration;
        i.active = false;
    }

    function withdrawStake() external {
        Info storage i = validators[msg.sender];
        require(block.timestamp >= i.jailEnd, "Still jailed");
        uint256 amt = i.stake;
        i.stake = 0;
        payable(msg.sender).transfer(amt);
    }

    function register(uint256 stakeAmt) external payable {
        require(msg.value == stakeAmt && stakeAmt >= minStake, "Bad stake");
        validators[msg.sender] = Info(stakeAmt, 0, true);
    }

    receive() external payable {}
}
