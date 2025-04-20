// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Online Storage Registry
 * -------------------------------------------------------------
 * • Users register file CIDs (IPFS / Arweave / Swarm) with size
 *   and an optional human‑readable tag.
 * • A small per‑byte fee (configurable) is paid in native coin.
 * • Owner can withdraw accumulated fees and update the price.
 *
 * NOTE
 * ----
 * This contract **does not** store the file itself—only its
 * content‑addressed identifier (e.g. an IPFS CID).  Retrieval
 * is still done through external distributed‑storage gateways.
 */
contract OnlineStorage is Ownable {
    struct File {
        string  cid;        // content identifier (e.g. IPFS CID)
        uint256 size;       // file size in bytes
        uint256 timestamp;  // block timestamp when stored
        string  tag;        // optional label
    }

    /// price in wei charged per byte (e.g. 1 gwei per kB => 1e9 / 1024)
    uint256 public pricePerByte = 1e9;

    /// user => list of files
    mapping(address => File[]) private _files;

    event FileStored(address indexed user, uint256 index, string cid, uint256 size);
    event PriceUpdated(uint256 pricePerByte);
    event Withdrawn(address indexed to, uint256 amount);

    constructor() Ownable(msg.sender) {}

    /* ─────────────  Public interface  ───────────── */

    /**
     * @notice Store a file reference.
     * @param cid  Content‑addressed identifier (IPFS hash, etc.).
     * @param size File size in bytes.
     * @param tag  Optional human‑readable label.
     */
    function storeFile(string calldata cid, uint256 size, string calldata tag) external payable {
        require(bytes(cid).length > 0, "empty cid");
        require(size > 0,               "size zero");

        uint256 cost = size * pricePerByte;
        require(msg.value >= cost, "insufficient fee");

        _files[msg.sender].push(File({
            cid: cid,
            size: size,
            timestamp: block.timestamp,
            tag: tag
        }));

        // refund excess (if any)
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit FileStored(msg.sender, _files[msg.sender].length - 1, cid, size);
    }

    /**
     * @notice Get number of files stored by a user.
     */
    function fileCount(address user) external view returns (uint256) {
        return _files[user].length;
    }

    /**
     * @notice Retrieve metadata for a user's file.
     * @param user  Owner of the file.
     * @param index File index (0 … fileCount‑1).
     */
    function getFile(address user, uint256 index)
        external
        view
        returns (string memory cid, uint256 size, uint256 timestamp, string memory tag)
    {
        require(index < _files[user].length, "index oob");
        File storage f = _files[user][index];
        return (f.cid, f.size, f.timestamp, f.tag);
    }

    /* ─────────────  Owner functions  ───────────── */

    /**
     * @notice Update the storage price.
     * @param newPrice Price per byte in wei.
     */
    function setPrice(uint256 newPrice) external onlyOwner {
        pricePerByte = newPrice;
        emit PriceUpdated(newPrice);
    }

    /**
     * @notice Withdraw accumulated fees.
     * @param to Recipient address.
     */
    function withdraw(address payable to) external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "nothing to withdraw");
        to.transfer(bal);
        emit Withdrawn(to, bal);
    }
}
