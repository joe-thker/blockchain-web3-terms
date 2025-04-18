// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SignedDataOffChain
 * @notice Verifies off‑chain messages signed by an authorized signer.
 *         Uses manual EIP‑191 prefixing and Ownable for access control.
 */
contract SignedDataOffChain is Ownable {
    using ECDSA for bytes32;

    /// @notice Authorized signer for off‑chain messages.
    address public authorizedSigner;

    event SignerUpdated(address indexed oldSigner, address indexed newSigner);
    event DataVerified(address indexed user, string data);

    /**
     * @param _signer The address authorized to sign off‑chain payloads.
     * @dev Passes msg.sender to Ownable so the deployer becomes the contract owner.
     */
    constructor(address _signer) Ownable(msg.sender) {
        require(_signer != address(0), "Invalid signer");
        authorizedSigner = _signer;
    }

    /**
     * @notice Change the authorized signer.
     * @param _signer The new signer address.
     * @dev Only the contract owner may call this.
     */
    function updateSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid signer");
        emit SignerUpdated(authorizedSigner, _signer);
        authorizedSigner = _signer;
    }

    /**
     * @notice Verify a signed off‑chain payload and emit an event.
     * @param user      The user address that was signed for.
     * @param data      The payload string.
     * @param signature The ECDSA signature by the authorized signer.
     */
    function verifySignedData(
        address user,
        string calldata data,
        bytes calldata signature
    ) external {
        // 1. Recreate the original message hash.
        bytes32 hash = keccak256(abi.encodePacked(user, data));
        // 2. Prefix according to EIP‑191: "\x19Ethereum Signed Message:\n32" + hash
        bytes32 prefixed = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        // 3. Recover the signer and verify.
        address signer = ECDSA.recover(prefixed, signature);
        require(signer == authorizedSigner, "Invalid signature");
        emit DataVerified(user, data);
    }
}
