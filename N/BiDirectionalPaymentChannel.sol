// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title BiDirectionalPaymentChannel
 * @notice Both participants deposit ETH. Off‑chain they exchange signed states
 *         (nonce, balA, balB). Either party closes by submitting the highest‑nonce state.
 */
contract BiDirectionalPaymentChannel {
    using ECDSA for bytes32;

    address public immutable partyA;
    address public immutable partyB;
    uint256 public immutable expires;
    bool    public open;

    // Highest state seen
    uint256 public bestNonce;
    uint256 public bestBalA;
    uint256 public bestBalB;

    event ChannelClosed(uint256 nonce, uint256 balA, uint256 balB);

    /**
     * @param _partyB  The counterparty to partyA
     * @param duration Lifetime of the channel in seconds
     */
    constructor(address _partyB, uint256 duration) payable {
        require(msg.value > 0, "Deposit required");
        partyA = msg.sender;
        partyB = _partyB;
        expires = block.timestamp + duration;
        open = true;
        bestNonce = 0;
        bestBalA  = msg.value;
        bestBalB  = 0;
    }

    /**
     * @notice Close channel by submitting a signed state from both parties
     * @param nonce   Monotonically increasing state nonce
     * @param balA    Balance for partyA
     * @param balB    Balance for partyB (balA + balB must equal initial deposit)
     * @param sigA    Signature by partyA over (nonce, balA, balB, this)
     * @param sigB    Signature by partyB over same data
     */
    function closeChannel(
        uint256 nonce,
        uint256 balA,
        uint256 balB,
        bytes calldata sigA,
        bytes calldata sigB
    ) external {
        require(open, "Channel already closed");
        require(block.timestamp <= expires, "Channel expired");
        require(balA + balB == address(this).balance, "Invalid total balances");
        require(nonce > bestNonce, "State is not newer");

        // Build the message digest as per EIP‑191
        bytes32 digest = keccak256(abi.encodePacked(nonce, balA, balB, address(this)))
                         .toEthSignedMessageHash();

        // Recover and verify both signatures
        require(digest.recover(sigA) == partyA, "Invalid signature from partyA");
        require(digest.recover(sigB) == partyB, "Invalid signature from partyB");

        // Update best state
        bestNonce = nonce;
        bestBalA  = balA;
        bestBalB  = balB;

        // Close channel and distribute funds
        open = false;
        emit ChannelClosed(nonce, balA, balB);
        payable(partyA).transfer(balA);
        payable(partyB).transfer(balB);

        // Destroy contract to refund any leftover (should be zero)
        selfdestruct(payable(msg.sender));
    }

    /**
     * @notice If the channel expires without close, either party can trigger a refund.
     */
    function claimTimeout() external {
        require(open, "Channel already closed");
        require(block.timestamp >= expires, "Channel not yet expired");
        open = false;
        emit ChannelClosed(bestNonce, bestBalA, bestBalB);
        payable(partyA).transfer(bestBalA);
        payable(partyB).transfer(bestBalB);
        selfdestruct(payable(msg.sender));
    }
}
