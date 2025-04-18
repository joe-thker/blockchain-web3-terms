// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @title OffLedgerCurrency
 * @notice Users deposit ETH → on‑chain balance. Off‑chain they issue signed
 *         vouchers for transfers; recipients redeem those vouchers on‑chain.
 */
contract OffLedgerCurrency is EIP712 {
    using ECDSA for bytes32;

    string public constant NAME    = "OffLedgerCurrency";
    string public constant VERSION = "1";

    // balances and nonces
    mapping(address => uint256) public balances;
    mapping(address => uint256) public nonces;
    // prevent replay
    mapping(bytes32 => bool) public usedVouchers;

    // EIP‑712 typehash for Voucher struct
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

    /// Deposit ETH to credit your off‑ledger balance
    function deposit() external payable {
        require(msg.value > 0, "Must deposit > 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// Withdraw ETH from your off‑ledger balance
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Redeem a signed voucher transferring `amount` from `from` → `msg.sender`.
     * @param from      Voucher creator.
     * @param amount    Amount to transfer.
     * @param deadline  Expiration timestamp.
     * @param signature EIP‑712 signature over the voucher.
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
        require(!usedVouchers[digest], "Voucher used");
        address signer = ECDSA.recover(digest, signature);
        require(signer == from, "Invalid signature");

        usedVouchers[digest] = true;
        nonces[from] = userNonce + 1;

        require(balances[from] >= amount, "Insufficient balance");
        balances[from] -= amount;
        balances[msg.sender] += amount;

        emit VoucherRedeemed(from, msg.sender, amount, userNonce);
    }
}
