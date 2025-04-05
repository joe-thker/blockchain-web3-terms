// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FallingWedgeERC721
 * @dev ERC721 token where each NFT has a "quality" attribute that is reduced on each transfer.
 * The current wedge fee is determined dynamically based on elapsed days since deployment:
 *
 *      currentWedgeFee = minWedgeFee + (elapsedDays * wedgeIncreaseRate)
 *
 * capped at maxWedgeFee. Before transferring, the NFT's quality is reduced by:
 *
 *      reduction = (tokenQuality * currentWedgeFee) / 10000
 */
contract FallingWedgeERC721 is ERC721, Ownable {
    // Mapping from tokenId to its quality attribute.
    mapping(uint256 => uint256) public tokenQuality;
    // Minimum wedge fee in basis points (e.g., 50 = 0.5%).
    uint256 public minWedgeFee;
    // Maximum wedge fee in basis points (e.g., 1000 = 10%).
    uint256 public maxWedgeFee;
    // Wedge fee increase rate per day in basis points.
    uint256 public wedgeIncreaseRate;
    // Deployment timestamp.
    uint256 public deploymentTime;
    // Internal counter for token IDs.
    uint256 private _nextTokenId;

    event QualityReduced(uint256 tokenId, uint256 newQuality);
    event WedgeFeeUpdated(uint256 minWedgeFee, uint256 maxWedgeFee, uint256 wedgeIncreaseRate);

    /**
     * @dev Constructor sets token name, symbol, and wedge fee parameters.
     * @param _minWedgeFee Minimum wedge fee in basis points.
     * @param _maxWedgeFee Maximum wedge fee in basis points.
     * @param _wedgeIncreaseRate Wedge fee increase rate per day in basis points.
     */
    constructor(
        uint256 _minWedgeFee,
        uint256 _maxWedgeFee,
        uint256 _wedgeIncreaseRate
    ) ERC721("Falling Wedge NFT", "FWNFT") Ownable(msg.sender) {
        require(_minWedgeFee <= _maxWedgeFee, "Min wedge fee must be <= max wedge fee");
        minWedgeFee = _minWedgeFee;
        maxWedgeFee = _maxWedgeFee;
        wedgeIncreaseRate = _wedgeIncreaseRate;
        deploymentTime = block.timestamp;
        _nextTokenId = 1;
    }

    /**
     * @dev Returns the current wedge fee (in basis points) based on elapsed days.
     */
    function currentWedgeFee() public view returns (uint256) {
        uint256 elapsedDays = (block.timestamp - deploymentTime) / 1 days;
        uint256 fee = minWedgeFee + (elapsedDays * wedgeIncreaseRate);
        if (fee > maxWedgeFee) {
            fee = maxWedgeFee;
        }
        return fee;
    }

    /**
     * @dev Mints a new NFT with an initial quality value.
     * @param initialQuality The starting quality for the NFT.
     */
    function mint(uint256 initialQuality) external onlyOwner {
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        tokenQuality[tokenId] = initialQuality;
    }

    /**
     * @dev Allows the owner to update the wedge fee parameters.
     */
    function updateWedgeFee(
        uint256 _minWedgeFee,
        uint256 _maxWedgeFee,
        uint256 _wedgeIncreaseRate
    ) external onlyOwner {
        require(_minWedgeFee <= _maxWedgeFee, "Min wedge fee must be <= max wedge fee");
        minWedgeFee = _minWedgeFee;
        maxWedgeFee = _maxWedgeFee;
        wedgeIncreaseRate = _wedgeIncreaseRate;
        emit WedgeFeeUpdated(minWedgeFee, maxWedgeFee, wedgeIncreaseRate);
    }

    /**
     * @dev Internal function that applies the falling wedge effect.
     * Reduces the NFT's quality by:
     *      reduction = (tokenQuality * currentWedgeFee) / 10000
     */
    function _applyFallingWedge(uint256 tokenId) internal {
        uint256 fee = currentWedgeFee();
        uint256 quality = tokenQuality[tokenId];
        uint256 reduction = (quality * fee) / 10000;
        uint256 newQuality = quality > reduction ? quality - reduction : 0;
        tokenQuality[tokenId] = newQuality;
        emit QualityReduced(tokenId, newQuality);
    }

    /**
     * @dev Overrides safeTransferFrom with data to apply the falling wedge logic.
     * Note: We do NOT override safeTransferFrom(address, address, uint256) because that
     * version is non-virtual in the version of OpenZeppelin you're using.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        _applyFallingWedge(tokenId);
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
