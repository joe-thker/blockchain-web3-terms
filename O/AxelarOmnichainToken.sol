// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";

/**
 * @title AxelarOmnichainToken
 * @notice ERC‑20 token that moves between chains via Axelar GMP.
 *         - burns on the source chain, mints on the destination.
 *         - pays gas via Axelar Gas Service.
 *         - implements AxelarExecutable to receive cross‑chain calls.
 */
contract AxelarOmnichainToken is ERC20, AxelarExecutable {
    IAxelarGasService public immutable gasService;

    /**
     * @param gateway_     Address of the Axelar Gateway contract.
     * @param gasService_  Address of the Axelar Gas Service contract.
     */
    constructor(address gateway_, address gasService_)
        ERC20("AxelarOmni", "AXOM")
        AxelarExecutable(gateway_)
    {
        gasService = IAxelarGasService(gasService_);
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }

    /**
     * @notice Send tokens to another chain.
     * @param dstChain    Name of the destination chain (e.g. "Avalanche").
     * @param dstAddress  Hex‑encoded contract address on the destination chain.
     * @param amount      Number of tokens to transfer.
     */
    function sendTokens(
        string calldata dstChain,
        string calldata dstAddress,
        uint256 amount
    ) external payable {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);

        // Payload: (sender, amount)
        bytes memory payload = abi.encode(msg.sender, amount);

        // Pay for cross‑chain gas
        gasService.payNativeGasForContractCall{ value: msg.value }(
            address(this),
            dstChain,
            dstAddress,
            payload,
            msg.sender
        );

        // Instruct Axelar Gateway to call the destination contract
        gateway().callContract(dstChain, dstAddress, payload);
    }

    /**
     * @inheritdoc AxelarExecutable
     * @dev Called by the Gateway once the cross‑chain message is validated.
     */
    function _execute(
        bytes32,               // commandId (unused)
        string calldata,       // sourceChain (unused)
        string calldata,       // sourceAddress (unused)
        bytes calldata payload // encoded (to, amount)
    ) internal override {
        (address to, uint256 amount) = abi.decode(payload, (address, uint256));
        _mint(to, amount);
    }
}
