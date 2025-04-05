// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FallingWedgeERC1155
 * @dev ERC1155 token contract with a dynamic burn fee that increases over time.
 * On every transfer, a portion of the tokens is burned according to the current burn fee.
 */
contract FallingWedgeERC1155 is ERC1155, Ownable {
    // Minimum burn fee in basis points (e.g., 50 = 0.5%)
    uint256 public minBurnFee;
    // Maximum burn fee in basis points (e.g., 1000 = 10%)
    uint256 public maxBurnFee;
    // Burn fee increase rate per day in basis points
    uint256 public burnFeeIncreaseRate;
    // Timestamp when the contract was deployed
    uint256 public deploymentTime;

    event BurnFeeApplied(uint256 tokenId, uint256 currentFee, uint256 burnAmount);

    /**
     * @dev Constructor sets the base URI and burn fee parameters.
     * @param uri_ Base URI for token metadata.
     * @param _minBurnFee Minimum burn fee in basis points.
     * @param _maxBurnFee Maximum burn fee in basis points.
     * @param _burnFeeIncreaseRate Burn fee increase rate per day in basis points.
     */
    constructor(
        string memory uri_,
        uint256 _minBurnFee,
        uint256 _maxBurnFee,
        uint256 _burnFeeIncreaseRate
    ) ERC1155(uri_) Ownable(msg.sender) {
        require(_minBurnFee <= _maxBurnFee, "Min burn fee must be <= max burn fee");
        minBurnFee = _minBurnFee;
        maxBurnFee = _maxBurnFee;
        burnFeeIncreaseRate = _burnFeeIncreaseRate;
        deploymentTime = block.timestamp;
    }

    /**
     * @dev Returns the current burn fee (in basis points) based on elapsed days.
     */
    function currentBurnFee() public view returns (uint256) {
        uint256 elapsedDays = (block.timestamp - deploymentTime) / 1 days;
        uint256 fee = minBurnFee + (elapsedDays * burnFeeIncreaseRate);
        if (fee > maxBurnFee) {
            fee = maxBurnFee;
        }
        return fee;
    }

    /**
     * @dev Overrides safeTransferFrom to apply the dynamic burn fee on a single token transfer.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        uint256 fee = currentBurnFee();
        uint256 burnAmount = (amount * fee) / 10000;
        uint256 transferAmount = amount - burnAmount;

        super.safeTransferFrom(from, to, id, transferAmount, data);
        _burn(from, id, burnAmount);
        emit BurnFeeApplied(id, fee, burnAmount);
    }

    /**
     * @dev Overrides safeBatchTransferFrom to apply the dynamic burn fee on batch transfers.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        uint256 fee = currentBurnFee();
        uint256 length = ids.length;
        uint256[] memory transferAmounts = new uint256[](length);
        uint256[] memory burnAmounts = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            burnAmounts[i] = (amounts[i] * fee) / 10000;
            transferAmounts[i] = amounts[i] - burnAmounts[i];
        }

        super.safeBatchTransferFrom(from, to, ids, transferAmounts, data);

        for (uint256 i = 0; i < length; i++) {
            _burn(from, ids[i], burnAmounts[i]);
            emit BurnFeeApplied(ids[i], fee, burnAmounts[i]);
        }
    }
}
