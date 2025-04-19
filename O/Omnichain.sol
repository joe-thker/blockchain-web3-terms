// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";

/**
 * @title OmnichainToken
 * @notice ERC‑20 token that can move between chains via LayerZero.
 *         - Users burn tokens on the source chain and mint on the destination.
 *         - Inherits NonblockingLzApp (which itself inherits Ownable), so we must
 *           pass msg.sender to the Ownable base constructor.
 */
contract OmnichainToken is ERC20, NonblockingLzApp {
    constructor(address _lzEndpoint)
        ERC20("OmnichainToken", "OCT")
        NonblockingLzApp(_lzEndpoint)
        Ownable(msg.sender)   // satisfy Ownable constructor
    {
        // Mint initial supply to deployer
        _mint(_msgSender(), 1_000_000 * 10**decimals());
    }

    /**
     * @notice Send tokens to another chain.
     * @param _dstChainId LayerZero destination chain ID.
     * @param _to         Recipient address on destination chain.
     * @param _amount     Amount of tokens to transfer.
     */
    function sendTokens(
        uint16 _dstChainId,
        address _to,
        uint256 _amount
    ) external payable {
        require(balanceOf(_msgSender()) >= _amount, "Insufficient balance");

        // Burn on source chain
        _burn(_msgSender(), _amount);

        // Encode the recipient and amount into the payload
        bytes memory toBytes = abi.encodePacked(_to);
        bytes memory payload = abi.encode(toBytes, _amount);

        // _lzSend expects 6 arguments in this version:
        //   (dstChainId, payload, refundAddress, zroPaymentAddress, adapterParams, nativeFee)
        _lzSend(
            _dstChainId,
            payload,
            payable(_msgSender()),   // refund any extra native fees
            address(0),               // zroPaymentAddress (for ZRO tokens) – not used
            bytes(""),                // adapterParams – empty for default
            msg.value                 // native fee to pay LayerZero relayer
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

        // Convert 20‑byte array to address
        address to;
        assembly {
            to := mload(add(toBytes, 20))
        }

        // Mint on the destination chain
        _mint(to, amount);
    }
}
