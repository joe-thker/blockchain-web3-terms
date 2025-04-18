// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title PaymentChannel
 * @notice Sender deposits ETH for a single recipient. They exchange off‑chain
 *         signed messages with cumulative pay‑out amounts. Recipient closes
 *         the channel on‑chain by submitting the highest‑value signed message.
 */
contract PaymentChannel {
    using ECDSA for bytes32;

    address public sender;
    address public recipient;
    uint256 public expires;
    uint256 public deposited;

    event ChannelClosed(address indexed by, uint256 amountToRecipient);

    /**
     * @param _recipient The channel’s counterparty.
     * @param duration   Channel lifetime in seconds.
     */
    constructor(address _recipient, uint256 duration) payable {
        require(msg.value > 0, "Must deposit ETH");
        sender = msg.sender;
        recipient = _recipient;
        deposited = msg.value;
        expires = block.timestamp + duration;
    }

    /**
     * @notice Close the channel with an off‑chain signature from the sender.
     * @param amount    Total payout to the recipient.
     * @param signature Signature from the sender authorizing `amount`.
     */
    function close(uint256 amount, bytes calldata signature) external {
        require(msg.sender == recipient || msg.sender == sender, "Not allowed");

        // Recreate the signed message: keccak256(amount, contract address)
        bytes32 digest = keccak256(abi.encodePacked(amount, address(this)))
                         .toEthSignedMessageHash();

        // Recover the signer and verify
        address signer = digest.recover(signature);
        require(signer == sender, "Invalid signature");

        // Distribute funds
        require(amount <= deposited, "Amount exceeds deposit");
        deposited -= amount;
        payable(recipient).transfer(amount);
        payable(sender).transfer(deposited);

        emit ChannelClosed(msg.sender, amount);

        // Destroy the contract and refund any leftovers to sender
        selfdestruct(payable(sender));
    }

    /**
     * @notice If the channel expires without close, sender can reclaim the funds.
     */
    function claimTimeout() external {
        require(block.timestamp >= expires, "Channel not yet expired");
        emit ChannelClosed(msg.sender, 0);
        selfdestruct(payable(sender));
    }
}
