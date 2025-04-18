// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @title OffLedgerCurrency
 * @notice A simple off‑ledger currency: users deposit Ether on‑chain to obtain balance,
 *         then transfer tokens off‑chain by signing “vouchers” that can be redeemed
 *         on‑chain by the recipient. Vouchers include a nonce and deadline to prevent
 *         replay and expiration.
 */
contract OffLedgerCurrency is EIP712 {
    using ECDSA for bytes32;

    string public constant NAME    = "OffLedgerCurrency";
    string public constant VERSION = "1";

    // User balances (in wei)
    mapping(address => uint256) public balances;
    // Nonce per user for voucher uniqueness
    mapping(address => uint256) public nonces;
    // Track used voucher signatures
    mapping(bytes32 => bool) public usedVouchers;

    // Voucher type hash for EIP‑712
    bytes32 private constant VOUCHER_TYPEHASH = keccak256(
        "Voucher(address from,address to,uint256 amount,uint256 nonce,uint256 deadline)"
    );

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event VoucherRedeemed(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 nonce
    );

    constructor() EIP712(NAME, VERSION) {}

    /**
     * @notice Deposit Ether to credit your off‑ledger balance.
     */
    function deposit() external payable {
        require(msg.value > 0, "Must deposit > 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw Ether from your off‑ledger balance.
     * @param amount Amount to withdraw.
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Redeem an off‑chain signed voucher transferring tokens from `from` to `msg.sender`.
     * @param from     The voucher creator (sender).
     * @param amount   Amount to transfer.
     * @param deadline Timestamp after which voucher is invalid.
     * @param signature EIP‑712 signature from `from`.
     */
    function redeemVoucher(
        address from,
        uint256 amount,
        uint256 deadline,
        bytes calldata signature
    ) external {
        require(block.timestamp <= deadline, "Voucher expired");

        uint256 userNonce = nonces[from];
        bytes32 structHash = keccak256(abi.encode(
            VOUCHER_TYPEHASH,
            from,
            msg.sender,
            amount,
            userNonce,
            deadline
        ));
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, signature);
        require(signer == from, "Invalid signature");

        // Prevent replay
        require(!usedVouchers[digest], "Voucher already used");
        usedVouchers[digest] = true;
        nonces[from] = userNonce + 1;

        // Perform transfer
        require(balances[from] >= amount, "Insufficient balance");
        balances[from] -= amount;
        balances[msg.sender] += amount;

        emit VoucherRedeemed(from, msg.sender, amount, userNonce);
    }
}
