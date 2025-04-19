// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";

/**
 * @title LayerZeroOmnichainToken
 * @notice ERC‑20 token that burns on the source chain and mints on the destination chain
 *         via LayerZero’s NonblockingLzApp.
 */
contract LayerZeroOmnichainToken is ERC20, NonblockingLzApp {
    constructor(address _lzEndpoint)
        ERC20("LayerZeroOmni", "LZOMNI")
        NonblockingLzApp(_lzEndpoint)
    {
        // Mint initial supply to deployer
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }

    /**
     * @notice Send tokens to another chain.
     * @param _dstChainId LayerZero destination chain ID.
     * @param _to         Recipient address on the destination chain.
     * @param _amount     Amount of tokens to transfer.
     */
    function sendTokens(
        uint16 _dstChainId,
        address _to,
        uint256 _amount
    ) external payable {
        require(balanceOf(_msgSender()) >= _amount, "Insufficient balance");

        // Burn locally
        _burn(_msgSender(), _amount);

        // Encode recipient and amount into the payload
        bytes memory toBytes = abi.encodePacked(_to);
        bytes memory payload = abi.encode(toBytes, _amount);

        // 6‑arg _lzSend:
        //  dstChainId, payload, refundAddress, zroPaymentAddress, adapterParams, nativeFee
        _lzSend(
            _dstChainId,
            payload,
            payable(_msgSender()),
            address(0),
            bytes(""),
            msg.value
        );
    }

    /// @inheritdoc NonblockingLzApp
    function _nonblockingLzReceive(
        uint16,         // _srcChainId
        bytes memory,   // _srcAddress
        uint64,         // _nonce
        bytes memory _payload
    ) internal override {
        // Decode the payload back into recipient and amount
        (bytes memory toBytes, uint256 amount) = abi.decode(_payload, (bytes, uint256));
        address to;
        assembly { to := mload(add(toBytes, 20)) }

        // Mint on the destination chain
        _mint(to, amount);
    }
}
