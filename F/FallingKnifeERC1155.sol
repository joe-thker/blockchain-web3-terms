// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FallingKnifeERC1155
 * @dev ERC1155 token contract that burns a percentage of tokens on each transfer.
 */
contract FallingKnifeERC1155 is ERC1155, Ownable {
    // Burn fee in basis points (e.g., 50 = 0.5%)
    uint256 public burnFee;
    event BurnFeeUpdated(uint256 newBurnFee);

    /**
     * @dev Constructor sets the base URI and burn fee.
     * @param uri_ Base URI for token metadata.
     * @param _burnFee Burn fee in basis points.
     */
    constructor(string memory uri_, uint256 _burnFee)
        ERC1155(uri_)
        Ownable(msg.sender)
    {
        require(_burnFee <= 1000, "Burn fee too high");
        burnFee = _burnFee;
    }

    /**
     * @dev Allows the owner to update the burn fee.
     */
    function updateBurnFee(uint256 newBurnFee) external onlyOwner {
        require(newBurnFee <= 1000, "Burn fee too high");
        burnFee = newBurnFee;
        emit BurnFeeUpdated(newBurnFee);
    }

    /**
     * @dev Overrides safeTransferFrom to implement the burn mechanism.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        uint256 fee = (amount * burnFee) / 10000;
        uint256 transferAmount = amount - fee;
        // Transfer the net amount to the recipient
        super.safeTransferFrom(from, to, id, transferAmount, data);
        // Burn the fee from the sender's balance
        _burn(from, id, fee);
    }

    /**
     * @dev Overrides safeBatchTransferFrom to implement the burn mechanism on each token type.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        uint256 length = ids.length;
        uint256[] memory transferAmounts = new uint256[](length);
        uint256[] memory fees = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            fees[i] = (amounts[i] * burnFee) / 10000;
            transferAmounts[i] = amounts[i] - fees[i];
        }
        // Transfer the net amounts to the recipient
        super.safeBatchTransferFrom(from, to, ids, transferAmounts, data);
        // Burn the fee amounts from the sender's balance
        for (uint256 i = 0; i < length; i++) {
            _burn(from, ids[i], fees[i]);
        }
    }
}
