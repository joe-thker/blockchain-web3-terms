// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DynamicERC827
/// @notice An ERC20 token extension implementing ERC827 functionality.
/// It supports transferring tokens and calling arbitrary functions on the target contract in a single transaction.
contract DynamicERC827 is ERC20, Ownable {
    /**
     * @notice Constructor initializes the token with a name, symbol, and initial supply.
     * @param _name The name of the token.
     * @param _symbol The token symbol.
     * @param initialSupply The initial token supply (in smallest units) minted to the deployer.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 initialSupply
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @notice Transfers tokens to an address and then calls a function on the recipient contract.
     * @param _to The recipient address.
     * @param _value The number of tokens to transfer.
     * @param _data The data payload for the call.
     * @return success True if the operation succeeds.
     */
    function transferAndCall(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool success) {
        require(transfer(_to, _value), "Transfer failed");
        // Convert calldata to memory for the call.
        bytes memory dataMemory = _data;
        (bool callSuccess, ) = _to.call(dataMemory);
        require(callSuccess, "Call failed");
        return true;
    }

    /**
     * @notice Approves an address to spend tokens and then calls a function on that address.
     * @param _spender The address allowed to spend tokens.
     * @param _value The number of tokens to approve.
     * @param _data The data payload for the call.
     * @return success True if the operation succeeds.
     */
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool success) {
        require(approve(_spender, _value), "Approve failed");
        bytes memory dataMemory = _data;
        (bool callSuccess, ) = _spender.call(dataMemory);
        require(callSuccess, "Call failed");
        return true;
    }

    /**
     * @notice Transfers tokens from one address to another and then calls a function on the recipient.
     * @param _from The address from which tokens are transferred.
     * @param _to The recipient address.
     * @param _value The number of tokens to transfer.
     * @param _data The data payload for the call.
     * @return success True if the operation succeeds.
     */
    function transferFromAndCall(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool success) {
        require(transferFrom(_from, _to, _value), "TransferFrom failed");
        bytes memory dataMemory = _data;
        (bool callSuccess, ) = _to.call(dataMemory);
        require(callSuccess, "Call failed");
        return true;
    }
}
