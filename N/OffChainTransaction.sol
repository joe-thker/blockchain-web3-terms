// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OffChainTransaction
 * @notice Enables users to submit signed transactions off-chain (meta-transactions),
 *         which relayers can then execute on-chain.
 *         Includes a simple deposit/withdraw demonstration.
 */
contract OffChainTransaction is EIP712, Ownable {
    using ECDSA for bytes32;

    // Track nonces for each user
    mapping(address => uint256) public nonces;

    // EIP‑712 domain parameters
    string private constant NAME    = "OffChainTransaction";
    string private constant VERSION = "1";

    // EIP‑712 typehash for the meta‑transaction
    bytes32 private constant META_TX_TYPEHASH =
        keccak256("MetaTransaction(uint256 nonce,address from,bytes functionData)");

    event MetaTransactionExecuted(
        address indexed user,
        address indexed relayer,
        bytes           functionData
    );
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    // Simple per-user balance mapping
    mapping(address => uint256) public balances;

    constructor() EIP712(NAME, VERSION) Ownable(msg.sender) {}

    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes   functionData;
    }

    function executeMetaTransaction(
        address        userAddress,
        bytes calldata functionData,
        bytes calldata signature
    ) external returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce:        nonces[userAddress],
            from:         userAddress,
            functionData: functionData
        });

        require(_verify(metaTx, signature), "Invalid signature");
        nonces[userAddress] += 1;

        emit MetaTransactionExecuted(userAddress, msg.sender, functionData);

        // Append the user address to calldata for context
        bytes memory data = abi.encodePacked(functionData, userAddress);
        (bool success, bytes memory returnData) = address(this).call(data);
        require(success, "Meta-transaction execution failed");
        return returnData;
    }

    function _hashMetaTransaction(MetaTransaction memory metaTx)
        internal view
        returns (bytes32)
    {
        return _hashTypedDataV4(
            keccak256(abi.encode(
                META_TX_TYPEHASH,
                metaTx.nonce,
                metaTx.from,
                keccak256(metaTx.functionData)
            ))
        );
    }

    function _verify(
        MetaTransaction memory metaTx,
        bytes calldata    signature
    ) internal view returns (bool) {
        return ECDSA.recover(_hashMetaTransaction(metaTx), signature) == metaTx.from;
    }

    function getNonce(address user) external view returns (uint256) {
        return nonces[user];
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Example functions to be called via meta‑transactions
    // ──────────────────────────────────────────────────────────────────────────

    function deposit() external payable {
        address sender = _msgSender();
        require(msg.value > 0, "No ETH sent");
        balances[sender] += msg.value;
        emit Deposit(sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        address sender = _msgSender();
        require(balances[sender] >= amount, "Insufficient balance");
        balances[sender] -= amount;
        payable(sender).transfer(amount);
        emit Withdrawal(sender, amount);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Override _msgSender to support meta‑transactions
    // ──────────────────────────────────────────────────────────────────────────

    function _msgSender()
        internal view
        override
        returns (address sender)
    {
        // If called through executeMetaTransaction, last 20 bytes of calldata is the user address
        if (msg.sender == address(this) && msg.data.length >= 20) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender = msg.sender;
        }
    }
}
