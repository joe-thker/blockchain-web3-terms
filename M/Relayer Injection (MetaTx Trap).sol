// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Relayer Injection (MetaTx Trap Example)
/// @notice Shows a vulnerable scenario of meta-transaction relayer injection
contract MetaTxVictim {
    using ECDSA for bytes32;

    mapping(address => uint256) public balances;

    event MetaTransferExecuted(address indexed from, address indexed to, uint256 amount);

    function metaTransfer(address from, address to, uint256 amount, bytes calldata signature) external {
        // Vulnerable: attacker might manipulate 'to'
        bytes32 hash = keccak256(abi.encodePacked(from, to, amount));
        address signer = recoverSigner(hash, signature);

        require(signer == from, "Invalid signer");

        balances[from] -= amount;
        balances[to] += amount;

        emit MetaTransferExecuted(from, to, amount);
    }

    function recoverSigner(bytes32 message, bytes memory sig) public pure returns (address) {
        bytes32 ethSignedHash = message.toEthSignedMessageHash();
        return ethSignedHash.recover(sig);
    }
}
