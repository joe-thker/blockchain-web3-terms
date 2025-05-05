// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SettlementLayerSuite
/// @notice Implements Layer1, State Channel, and Rollup Settlement mechanisms
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
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

/// 1) Layer-1 On-Chain Settlement
contract Layer1Settlement is Base, ReentrancyGuard {
    mapping(address => uint) public balances;

    // deposit into the contract
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // --- Attack: naive transfer, no CEI, full gas
    function settleInsecure(address payable to, uint amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        // Effects after interaction
        to.call{ value: amount }("");
        balances[msg.sender] -= amount;
    }

    // --- Defense: CEI + reentrancy guard + gas stipend
    function settleSecure(address payable to, uint amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        // Effects
        balances[msg.sender] -= amount;
        // Interaction with limited gas
        (bool ok,) = to.call{ value: amount, gas: 2300 }("");
        require(ok, "Transfer failed");
    }
}

/// 2) State Channel Settlement
contract StateChannelSettlement is Base {
    struct Channel {
        address partyA;
        address partyB;
        uint    balanceA;
        uint    balanceB;
        uint    version;
        bool    open;
    }

    mapping(bytes32 => Channel) public channels;

    // --- Attack: open channel without requiring deposits
    function openChannelInsecure(
        bytes32 channelId,
        address partyB
    ) external payable {
        channels[channelId] = Channel(msg.sender, partyB, msg.value, 0, 0, true);
    }

    // --- Defense: require both parties deposit and register
    function openChannelSecure(
        bytes32 channelId,
        address partyB
    ) external payable onlyOwner {
        require(msg.value > 0, "Need deposit");
        Channel storage c = channels[channelId];
        require(!c.open, "Already open");
        c.partyA = msg.sender;
        c.partyB = partyB;
        c.balanceA = msg.value;
        c.balanceB = 0;
        c.version = 0;
        c.open = true;
    }

    // --- Attack: submit state without verifying signature or version
    function closeChannelInsecure(
        bytes32 channelId,
        uint balA,
        uint balB
    ) external {
        Channel storage c = channels[channelId];
        require(c.open, "Closed");
        // distribute forcibly
        payable(c.partyA).transfer(balA);
        payable(c.partyB).transfer(balB);
        c.open = false;
    }

    // --- Defense: require both signatures and higher version
    function closeChannelSecure(
        bytes32 channelId,
        uint balA,
        uint balB,
        uint v,
        bytes calldata sigA,
        bytes calldata sigB
    ) external {
        Channel storage c = channels[channelId];
        require(c.open, "Closed");
        require(v > c.version, "Stale state");
        bytes32 stateHash = keccak256(abi.encodePacked(channelId, balA, balB, v));
        // both parties must have signed this stateHash
        require(_verifySig(c.partyA, stateHash, sigA), "Bad sigA");
        require(_verifySig(c.partyB, stateHash, sigB), "Bad sigB");
        // distribution
        c.open = false;
        payable(c.partyA).transfer(balA);
        payable(c.partyB).transfer(balB);
    }

    function _verifySig(address signer, bytes32 hash, bytes memory signature) internal pure returns (bool) {
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(hash);
        return ECDSA.recover(ethHash, signature) == signer;
    }
}

/// Minimal ECDSA library for signature recovery
library ECDSA {
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "Invalid sig length");
        bytes32 r; bytes32 s; uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return ecrecover(hash, v, r, s);
    }
}

/// 3) Rollup Batch Settlement
contract RollupSettlement is Base {
    bytes32 public currentRoot;
    uint    public maxWithdrawals = 100;

    mapping(address => uint) public pending;  // queued withdrawals

    // --- Attack: post new root without verification
    function postRootInsecure(bytes32 newRoot) external {
        currentRoot = newRoot;
    }

    // --- Defense: onlyOwner + optional fraud proof integration
    function postRootSecure(bytes32 newRoot) external onlyOwner {
        // (in optimistic rollup, would accept then allow challenge)
        currentRoot = newRoot;
    }

    // --- Attack: withdraw without proof
    function withdrawInsecure(uint amount) external {
        require(pending[msg.sender] + amount <= 1e60, "Limit");
        pending[msg.sender] += amount;
    }

    // --- Defense: require Merkle-inclusion proof of account balance
    function withdrawSecure(
        uint amount,
        bytes32[] calldata proof,
        bytes32  leaf
    ) external {
        // verify leaf corresponds to user and amount
        require(leaf == keccak256(abi.encodePacked(msg.sender, amount)), "Bad leaf");
        require(_verifyProof(leaf, proof), "Invalid proof");
        pending[msg.sender] += amount;
    }

    function _verifyProof(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        bytes32 hash = leaf;
        for (uint i = 0; i < proof.length; i++) {
            hash = keccak256(abi.encodePacked(hash, proof[i]));
        }
        return hash == currentRoot;
    }
}
