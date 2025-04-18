// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OffChainOracle
 * @notice Fetches off‑chain data via a Chainlink oracle.
 *         - Owner configures LINK token, oracle, jobId, fee.
 *         - Anyone can request data by URL & JSON path.
 *         - The callback writes the result into a public mapping.
 */
contract OffChainOracle is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;

    /// @notice LINK token address
    address public immutable LINK_TOKEN;
    /// @notice Oracle node address
    address public oracle;
    /// @notice Chainlink job ID
    bytes32 public jobId;
    /// @notice Fee in LINK (wei) per request
    uint256 public fee;

    /// @notice Stores results keyed by request ID
    mapping(bytes32 => string) public results;

    event DataRequested(bytes32 indexed requestId, string url, string path);
    event DataFulfilled(bytes32 indexed requestId, string data);

    /**
     * @param _linkToken LINK token address
     * @param _oracle    Oracle node address
     * @param _jobId     Job ID on the Chainlink node
     * @param _fee       Fee in LINK (wei) per request
     */
    constructor(
        address _linkToken,
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) Ownable(msg.sender) {
        LINK_TOKEN = _linkToken;
        _setChainlinkToken(_linkToken);
        _setChainlinkOracle(_oracle);

        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    /**
     * @notice Request off‑chain data from a public API.
     * @param url  The full URL of the API endpoint.
     * @param path The JSON path to extract (comma‑delimited).
     * @return requestId The Chainlink request ID.
     */
    function requestData(string calldata url, string calldata path)
        external
        returns (bytes32 requestId)
    {
        Chainlink.Request memory req = _buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        // Add parameters to the request
        req.add("get", url);
        req.add("path", path);

        // Send the request
        requestId = _sendChainlinkRequest(req, fee);
        emit DataRequested(requestId, url, path);
    }

    /**
     * @notice Callback for the oracle to call with the result.
     * @param _requestId The ID returned by `requestData`.
     * @param _data      The bytes32-encoded result.
     */
    function fulfill(bytes32 _requestId, bytes32 _data)
        external
        recordChainlinkFulfillment(_requestId)
    {
        // Convert bytes32 to string, trimming trailing zeros
        bytes memory raw = abi.encodePacked(_data);
        uint256 len = raw.length;
        while (len > 0 && raw[len - 1] == 0) {
            len--;
        }
        bytes memory trimmed = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            trimmed[i] = raw[i];
        }
        string memory result = string(trimmed);

        results[_requestId] = result;
        emit DataFulfilled(_requestId, result);
    }

    /** OWNER‑ONLY ACTIONS */

    /// @notice Update the oracle node address
    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
        _setChainlinkOracle(_oracle);
    }

    /// @notice Update the Chainlink job ID
    function setJobId(bytes32 _jobId) external onlyOwner {
        jobId = _jobId;
    }

    /// @notice Update the LINK fee per request
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /// @notice Withdraw any LINK balance in the contract
    function withdrawLink() external onlyOwner {
        LinkTokenInterface(LINK_TOKEN).transfer(
            msg.sender,
            LinkTokenInterface(LINK_TOKEN).balanceOf(address(this))
        );
    }
}
