// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title StateChannelSuite
/// @notice 1) BasicPaymentChannel, 2) ChannelEscrow, 3) VirtualChannelDispute

////////////////////////////////////////////////////////////////////////////////
// 1) Basic Payment Channel
////////////////////////////////////////////////////////////////////////////////
contract BasicPaymentChannel {
    address public partyA;
    address public partyB;
    uint256 public challengeEnd;
    uint256 public challengeWindow = 1 hours;

    struct State { uint256 nonce; uint256 balanceA; uint256 balanceB; }
    State  public agreedState;
    bool   public closing;
    
    constructor(address _B) payable {
        partyA = msg.sender;
        partyB = _B;
    }

    // --- Attack: allow close with any lower‐nonce state
    function closeInsecure(
        uint256 nonce,
        uint256 balA,
        uint256 balB,
        bytes memory sigA,
        bytes memory sigB
    ) external {
        // no nonce check
        require(_verify(partyA, nonce, balA, balB, sigA), "Bad A sig");
        require(_verify(partyB, nonce, balA, balB, sigB), "Bad B sig");
        payable(partyA).transfer(balA);
        payable(partyB).transfer(balB);
        selfdestruct(payable(partyA));
    }

    // --- Defense: enforce monotonic nonce + challenge window
    function closeSecure(
        uint256 nonce,
        uint256 balA,
        uint256 balB,
        bytes memory sigA,
        bytes memory sigB
    ) external {
        require(nonce > agreedState.nonce, "Stale state");
        require(_verify(partyA, nonce, balA, balB, sigA), "Bad A sig");
        require(_verify(partyB, nonce, balA, balB, sigB), "Bad B sig");
        agreedState = State(nonce, balA, balB);
        // start challenge
        if (!closing) {
            closing = true;
            challengeEnd = block.timestamp + challengeWindow;
            return;
        }
    }

    // finalize after window
    function finalize() external {
        require(closing && block.timestamp >= challengeEnd, "In challenge");
        payable(partyA).transfer(agreedState.balanceA);
        payable(partyB).transfer(agreedState.balanceB);
        selfdestruct(payable(partyA));
    }

    function _verify(address signer, uint256 nonce, uint256 a, uint256 b, bytes memory sig) internal view returns (bool) {
        bytes32 h = keccak256(abi.encodePacked(address(this), nonce, a, b));
        bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(sig, (bytes32,bytes32,uint8));
        return ecrecover(msgHash, v, r, s) == signer;
    }
}

////////////////////////////////////////////////////////////////////////////////
// 2) Reentrant Deposit/Withdraw (Channel Escrow)
////////////////////////////////////////////////////////////////////////////////
contract ChannelEscrow is ReentrancyGuard {
    mapping(address=>uint256) public deposits;

    // --- Attack: insecure withdraw allows reentrancy
    function withdrawInsecure(uint256 amount) external {
        require(deposits[msg.sender] >= amount, "Insufficient");
        // Interaction first
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");
        // then effect
        deposits[msg.sender] -= amount;
    }

    // --- Defense: CEI pattern + nonReentrant
    function withdrawSecure(uint256 amount) external nonReentrant {
        require(deposits[msg.sender] >= amount, "Insufficient");
        // Effects
        deposits[msg.sender] -= amount;
        // Interaction
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");
    }

    function deposit() external payable {
        deposits[msg.sender] += msg.value;
    }
}

////////////////////////////////////////////////////////////////////////////////
// 3) Virtual Channel Dispute (Multi‐hop)
////////////////////////////////////////////////////////////////////////////////
contract VirtualChannelDispute {
    struct Hop { address from; address to; uint256 amount; uint256 expiry; }
    mapping(bytes32=>Hop) public hops;

    // --- Attack: no expiry enforcement allows locked funds
    function openInsecure(bytes32 hopId, address from, address to, uint256 amt) external payable {
        require(msg.value == amt, "Bad amt");
        hops[hopId] = Hop(from, to, amt, 0);
    }

    function closeInsecure(bytes32 hopId) external {
        Hop memory h = hops[hopId];
        require(msg.sender == h.to, "Only to");
        // no expiry check
        payable(h.to).transfer(h.amount);
        delete hops[hopId];
    }

    // --- Defense: set per‐hop expiry and enforce before close
    function openSecure(bytes32 hopId, address from, address to, uint256 amt, uint256 duration) external payable {
        require(msg.value == amt, "Bad amt");
        hops[hopId] = Hop(from, to, amt, block.timestamp + duration);
    }

    function closeSecure(bytes32 hopId) external {
        Hop memory h = hops[hopId];
        require(msg.sender == h.to, "Only to");
        require(block.timestamp <= h.expiry, "Hop expired");
        payable(h.to).transfer(h.amount);
        delete hops[hopId];
    }

    // refund by `from` after expiry
    function refund(bytes32 hopId) external {
        Hop memory h = hops[hopId];
        require(msg.sender == h.from, "Only from");
        require(h.expiry > 0 && block.timestamp > h.expiry, "Not expired");
        payable(h.from).transfer(h.amount);
        delete hops[hopId];
    }
}
