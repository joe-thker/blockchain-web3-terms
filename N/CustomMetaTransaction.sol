// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CustomMetaTransaction
 * @notice Users sign a “MetaTransaction(nonce,from,callData)” off‑chain.
 *         Relayers call `executeMetaTransaction` to execute the payload on‑chain.
 *         `_msgSender()` inside called functions reflects the original user.
 */
contract CustomMetaTransaction is Context, EIP712, Ownable {
    using ECDSA for bytes32;

    mapping(address => uint256) public nonces;
    mapping(address => uint256) public balances;

    string private constant NAME    = "CustomMetaTransaction";
    string private constant VERSION = "1";

    bytes32 private constant META_TX_TYPEHASH =
        keccak256("MetaTransaction(uint256 nonce,address from,bytes functionData)");

    event MetaTransactionExecuted(address indexed user, address indexed relayer, bytes functionData);
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    constructor() 
        EIP712(NAME, VERSION) 
        Ownable(msg.sender) 
    {}

    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes   functionData;
    }

    /// @notice Execute a signed meta‑transaction.
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

        // Append userAddress so _msgSender() will return it.
        bytes memory data = abi.encodePacked(functionData, userAddress);
        (bool ok, bytes memory ret) = address(this).call(data);
        require(ok, "Meta-transaction failed");
        return ret;
    }

    function _hashMetaTransaction(MetaTransaction memory metaTx)
        internal view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            META_TX_TYPEHASH,
            metaTx.nonce,
            metaTx.from,
            keccak256(metaTx.functionData)
        )));
    }

    function _verify(MetaTransaction memory metaTx, bytes calldata sig)
        internal view returns (bool)
    {
        return ECDSA.recover(_hashMetaTransaction(metaTx), sig) == metaTx.from;
    }

    function getNonce(address user) external view returns (uint256) {
        return nonces[user];
    }

    // ───────── Example Functions ─────────

    function deposit() external payable {
        address sender = _msgSender();
        require(msg.value > 0, "No ETH");
        balances[sender] += msg.value;
        emit Deposit(sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        address sender = _msgSender();
        require(balances[sender] >= amount, "Insufficient");
        balances[sender] -= amount;
        payable(sender).transfer(amount);
        emit Withdrawal(sender, amount);
    }

    // ───────── Override Context ─────────

    /** @dev Extract sender from end of calldata if called via executeMetaTransaction */
    function _msgSender()
        internal view
        override(Context)
        returns (address sender)
    {
        if (msg.sender == address(this) && msg.data.length >= 20) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender = msg.sender;
        }
    }
}
