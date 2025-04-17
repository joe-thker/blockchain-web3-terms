// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title BasicNotarization
 * @notice Anyone can notarize a document by its hash.  
 *         Records the block timestamp on first submission.
 */
contract BasicNotarization {
    // docHash => timestamp
    mapping(bytes32 => uint256) public notarizedAt;

    /// @notice Emitted when a document is notarized.
    event Notarized(bytes32 indexed docHash, uint256 timestamp);

    /**
     * @notice Notarize a document hash.
     * @param docHash The keccak256 hash of the document.
     */
    function notarize(bytes32 docHash) external {
        require(docHash != bytes32(0), "Invalid hash");
        require(notarizedAt[docHash] == 0, "Already notarized");
        notarizedAt[docHash] = block.timestamp;
        emit Notarized(docHash, block.timestamp);
    }

    /**
     * @notice Verify when a document was notarized.
     * @param docHash The document hash.
     * @return timestamp The block timestamp when first notarized (or 0 if never).
     */
    function verify(bytes32 docHash) external view returns (uint256 timestamp) {
        return notarizedAt[docHash];
    }
}
