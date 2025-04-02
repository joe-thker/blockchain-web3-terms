// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice A simplified DEX interface for a generic swap function.
interface IDex {
    /// @notice Swaps a specified amount of tokenIn for at least minOut of tokenOut, sending the result to `to`.
    /// @param tokenIn The address of the input token.
    /// @param tokenOut The address of the output token.
    /// @param amountIn The exact amount of tokenIn to swap.
    /// @param minOut The minimum acceptable amount of tokenOut.
    /// @param to The address to receive the swapped tokens.
    /// @return amountOut The actual amount of tokenOut received from the swap.
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minOut,
        address to
    ) external returns (uint256 amountOut);
}

/// @title DexAggregator
/// @notice A dynamic, optimized, and secure aggregator for multiple DEXes. 
/// Allows the owner to register or remove DEX addresses, and provides a swap function 
/// that calls a chosen DEX’s swap method.
contract DexAggregator is Ownable, ReentrancyGuard {
    /// @notice Data structure for storing a DEX’s info.
    struct DexInfo {
        address dexAddress;
        bool active;
    }

    // Array of registered DEX info
    DexInfo[] public dexList;
    // Mapping from DEX address to its index in dexList (plus 1 for existence check)
    mapping(address => uint256) public dexIndexPlusOne;

    // --- Events ---
    event DexRegistered(address indexed dexAddr);
    event DexRemoved(address indexed dexAddr);
    event TokensSwapped(
        address indexed dex,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 minOut,
        uint256 amountOut
    );

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Registers a new DEX address in the aggregator. Only the owner can call this.
    /// @param dexAddr The address of a contract implementing the IDex interface.
    function registerDex(address dexAddr) external onlyOwner {
        require(dexAddr != address(0), "Invalid dex address");
        require(dexIndexPlusOne[dexAddr] == 0, "DEX already registered");

        // Add new DexInfo to array
        dexList.push(DexInfo({ dexAddress: dexAddr, active: true }));
        // Store indexPlusOne as array length
        dexIndexPlusOne[dexAddr] = dexList.length;

        emit DexRegistered(dexAddr);
    }

    /// @notice Removes a registered DEX address. Only the owner can call this.
    /// @param dexAddr The address of the DEX to remove.
    function removeDex(address dexAddr) external onlyOwner {
        uint256 idxPlusOne = dexIndexPlusOne[dexAddr];
        require(idxPlusOne != 0, "DEX not registered");
        uint256 idx = idxPlusOne - 1;

        // Mark it inactive
        dexList[idx].active = false;

        // We won't remove from array to keep indexes stable, but we mark it inactive.
        // For a full removal, we’d do a swap-with-last approach, but that changes indexes for other DEX addresses.

        dexIndexPlusOne[dexAddr] = 0;
        emit DexRemoved(dexAddr);
    }

    /// @notice Returns the total number of DEXes ever registered (including inactive).
    /// @return The length of dexList array.
    function totalDexCount() external view returns (uint256) {
        return dexList.length;
    }

    /// @notice Retrieves the DexInfo for a given index in dexList.
    /// @param index The index in the dexList array.
    /// @return A DexInfo struct with the DEX’s address and active status.
    function getDexInfo(uint256 index) external view returns (DexInfo memory) {
        require(index < dexList.length, "Index out of range");
        return dexList[index];
    }

    /// @notice Swaps tokens through a chosen DEX address, forwarding a call to its swap method.
    /// @param dexAddr The DEX address to route the swap. Must be registered and active.
    /// @param tokenIn The address of the input token.
    /// @param tokenOut The address of the output token.
    /// @param amountIn The amount of tokenIn to swap.
    /// @param minOut The minimum acceptable amount of tokenOut.
    /// @param to The address to receive the swapped tokenOut.
    /// @return amountOut The actual amount of tokenOut received from the DEX swap.
    function swapOnDex(
        address dexAddr,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minOut,
        address to
    ) external nonReentrant returns (uint256 amountOut)
    {
        uint256 idxPlusOne = dexIndexPlusOne[dexAddr];
        require(idxPlusOne != 0, "DEX not registered");
        DexInfo memory info = dexList[idxPlusOne - 1];
        require(info.active, "DEX is inactive");

        // Transfer tokenIn from user to aggregator
        // For an ERC20 tokenIn, the user must have approved this aggregator for amountIn.
        // We'll do the actual swap using an IDex interface call.

        // Pull tokenIn into aggregator
        // (Note: user must have called tokenIn.approve(this, amountIn) before.)
        require(_safeTransferFrom(tokenIn, msg.sender, address(this), amountIn), "tokenIn transfer failed");

        // Approve the DEX to spend aggregator's tokenIn so it can do the swap
        require(_safeApprove(tokenIn, dexAddr, amountIn), "DEX approve failed");

        // Call the DEX’s swap function
        amountOut = IDex(dexAddr).swap(tokenIn, tokenOut, amountIn, minOut, address(this));

        // Revoke approval to avoid leaving aggregator’s tokenIn allowance.
        _safeApprove(tokenIn, dexAddr, 0);

        // Transfer tokenOut from aggregator to the 'to' address
        require(_safeTransfer(tokenOut, to, amountOut), "tokenOut transfer failed");

        emit TokensSwapped(dexAddr, tokenIn, tokenOut, amountIn, minOut, amountOut);
    }

    /// @notice Helper function to transfer an ERC20 token safely.
    /// @param token The ERC20 token address.
    /// @param to The recipient address.
    /// @param amount The amount to transfer.
    /// @return True if transfer succeeded, false otherwise.
    function _safeTransfer(address token, address to, uint256 amount) internal returns (bool) {
        // We assume the token is standard ERC20
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), to, amount)
        );
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }

    /// @notice Helper function to transferFrom an ERC20 token safely.
    /// @param token The ERC20 token address.
    /// @param from The sender address.
    /// @param to The recipient address.
    /// @param amount The amount to transfer.
    /// @return True if transfer succeeded, false otherwise.
    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal returns (bool) {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(bytes4(keccak256("transferFrom(address,address,uint256)")), from, to, amount)
        );
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }

    /// @notice Helper function to approve an ERC20 token safely.
    /// @param token The ERC20 token address.
    /// @param spender The spender address.
    /// @param amount The amount of allowance.
    /// @return True if approval succeeded, false otherwise.
    function _safeApprove(address token, address spender, uint256 amount) internal returns (bool) {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(bytes4(keccak256("approve(address,uint256)")), spender, amount)
        );
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }
}
