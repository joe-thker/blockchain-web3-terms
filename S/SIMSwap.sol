// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SIMSwapSuite
/// @notice Implements OTPWallet, SMSRecovery, and SIMInsurance modules
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

/// Interface for verifying oracle signatures
interface IOracle {
    function verify(bytes32 msgHash, bytes calldata sig) external view returns (bool);
}

//// 1) OTP-Protected Wallet
contract OTPWallet is Base, ReentrancyGuard {
    // Registered phone hash
    bytes32 public phoneHash;
    // OTP nonces used
    mapping(uint256 => bool) public usedNonce;
    // Rate limiting: last timestamp per phoneHash
    uint256 public lastOTPTime;
    uint256 public constant OTP_INTERVAL = 60; // seconds

    event PhoneUpdated(bytes32 newHash);
    event Executed(address to, uint256 value, bytes data);

    // --- Attack: no nonce or expiry, anyone with an OTP can replay
    function executeInsecure(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 otp
    ) external {
        // naive: just check otp against stored hash
        require(keccak256(abi.encodePacked(otp)) == phoneHash, "Bad OTP");
        (bool ok,) = to.call{value: value}(data);
        require(ok, "Call failed");
        emit Executed(to, value, data);
    }

    // --- Defense: single-use nonce + timestamp + rate-limit + onlyOwner phone updates
    function executeSecure(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 otp,
        uint256 nonce,
        uint256 expiry
    ) external nonReentrant {
        require(block.timestamp <= expiry, "OTP expired");
        require(!usedNonce[nonce], "OTP replay");
        // rate-limit to one OTP per interval
        require(block.timestamp >= lastOTPTime + OTP_INTERVAL, "Too many OTPs");
        lastOTPTime = block.timestamp;
        usedNonce[nonce] = true;
        // verify OTP hashed with nonce
        require(keccak256(abi.encodePacked(otp, nonce)) == phoneHash, "Bad OTP");
        (bool ok,) = to.call{value: value}(data);
        require(ok, "Call failed");
        emit Executed(to, value, data);
    }

    // Only owner can update phoneHash, requiring on-chain signing off-chain
    function updatePhoneHash(bytes32 newHash) external onlyOwner {
        phoneHash = newHash;
        emit PhoneUpdated(newHash);
    }

    receive() external payable {}
}

//// 2) SMS-Recovery Module
contract SMSRecovery is Base, ReentrancyGuard {
    IOracle public oracle;
    uint256 public recoveryDelay = 1 days;
    struct Request { address wallet; uint256 timestamp; }
    mapping(bytes32 => Request) public requests;
    mapping(bytes32 => bool) public usedRequest;

    event RecoveryRequested(bytes32 reqId, address wallet, uint256 when);
    event RecoveryFinalized(bytes32 reqId, address wallet);

    constructor(address oracleAddr) {
        oracle = IOracle(oracleAddr);
    }

    // --- Attack: attacker calls finalize without valid oracle sig
    function finalizeInsecure(
        bytes32 reqId,
        address wallet,
        bytes calldata sig
    ) external {
        // no oracle check
        delete requests[reqId];
        payable(wallet).transfer(address(this).balance);
        emit RecoveryFinalized(reqId, wallet);
    }

    // --- Defense: require oracle sig + nonce + delay + replay protection
    function requestRecovery(bytes32 reqId, address wallet) external {
        require(requests[reqId].wallet == address(0), "Already requested");
        requests[reqId] = Request(wallet, block.timestamp);
        emit RecoveryRequested(reqId, wallet, block.timestamp);
    }

    function finalizeSecure(
        bytes32 reqId,
        bytes calldata oracleSig
    ) external nonReentrant {
        Request memory r = requests[reqId];
        require(r.wallet != address(0), "No such request");
        require(!usedRequest[reqId], "Already used");
        require(block.timestamp >= r.timestamp + recoveryDelay, "Too soon");
        // verify oracle attests to (reqId, wallet, timestamp)
        bytes32 h = keccak256(abi.encodePacked(reqId, r.wallet, r.timestamp));
        require(oracle.verify(h, oracleSig), "Bad oracle sig");
        usedRequest[reqId] = true;
        delete requests[reqId];
        // transfer funds to wallet as recovery
        payable(r.wallet).transfer(address(this).balance);
        emit RecoveryFinalized(reqId, r.wallet);
    }

    receive() external payable {}
}

//// 3) SIM-Swap Insurance Payout
contract SIMInsurance is Base {
    IOracle public oracleA;
    IOracle public oracleB;
    uint256 public payoutDelay = 12 hours;
    struct Claim { address claimant; uint256 timestamp; bool paid; }
    mapping(bytes32 => Claim) public claims;
    event ClaimFiled(bytes32 claimId, address claimant, uint256 when);
    event ClaimPaid(bytes32 claimId, address claimant);

    constructor(address _oa, address _ob) {
        oracleA = IOracle(_oa);
        oracleB = IOracle(_ob);
    }

    // --- Attack: single oracle triggers false payout immediately
    function payInsecure(bytes32 claimId, bytes calldata sig) external {
        // no multi-oracle or delay
        delete claims[claimId];
        payable(msg.sender).transfer(1 ether);
        emit ClaimPaid(claimId, msg.sender);
    }

    // --- Defense: multi-source oracle consensus + delay + replay protection
    function fileClaim(bytes32 claimId) external {
        require(claims[claimId].claimant == address(0), "Already filed");
        claims[claimId] = Claim(msg.sender, block.timestamp, false);
        emit ClaimFiled(claimId, msg.sender, block.timestamp);
    }

    function paySecure(
        bytes32 claimId,
        bytes calldata sigA,
        bytes calldata sigB
    ) external {
        Claim storage c = claims[claimId];
        require(c.claimant == msg.sender, "Not claimant");
        require(!c.paid, "Already paid");
        require(block.timestamp >= c.timestamp + payoutDelay, "Too early");
        // verify both oracles agree on claimId
        bytes32 h = keccak256(abi.encodePacked(claimId, msg.sender, c.timestamp));
        require(oracleA.verify(h, sigA), "Bad sigA");
        require(oracleB.verify(h, sigB), "Bad sigB");
        c.paid = true;
        payable(msg.sender).transfer(1 ether);
        emit ClaimPaid(claimId, msg.sender);
    }

    receive() external payable {}
}
