// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title CoreWallet
/// @notice A dynamic, optimized, and secure smart wallet contract that can hold Ether and ERC20 tokens.
/// The owner can add or remove additional authorized addresses. Authorized addresses can execute arbitrary calls
/// and transfer funds on behalf of the wallet.
contract CoreWallet is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Mapping to track additional authorized addresses (besides the owner).
    mapping(address => bool) public authorized;

    // --- Events ---
    event AuthorizedAdded(address indexed account);
    event AuthorizedRemoved(address indexed account);
    event Executed(address indexed target, uint256 value, bytes data, bytes result);
    event EtherWithdrawn(address indexed to, uint256 amount);
    event TokenTransferred(address indexed token, address indexed to, uint256 amount);
    event Received(address indexed sender, uint256 amount);

    /// @notice Modifier to restrict function calls to only the owner or authorized addresses.
    modifier onlyAuthorized() {
        require(msg.sender == owner() || authorized[msg.sender], "Not authorized");
        _;
    }

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {
        // Owner is set via Ownable.
    }

    /// @notice Allows the owner to add an authorized address.
    /// @param account The address to authorize.
    function addAuthorized(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        require(!authorized[account], "Already authorized");
        authorized[account] = true;
        emit AuthorizedAdded(account);
    }

    /// @notice Allows the owner to remove an authorized address.
    /// @param account The address to remove.
    function removeAuthorized(address account) external onlyOwner {
        require(authorized[account], "Address not authorized");
        authorized[account] = false;
        emit AuthorizedRemoved(account);
    }

    /// @notice Executes an arbitrary call from this wallet.
    /// @param target The target address to call.
    /// @param value The amount of Ether (in wei) to send.
    /// @param data The calldata for the call.
    /// @return result The returned data from the call.
    function executeCall(address target, uint256 value, bytes calldata data)
        external
        onlyAuthorized
        nonReentrant
        returns (bytes memory result)
    {
        require(target != address(0), "Invalid target");
        (bool success, bytes memory res) = target.call{value: value}(data);
        require(success, "Call failed");
        emit Executed(target, value, data, res);
        return res;
    }

    /// @notice Withdraws Ether from the wallet to the caller.
    /// @param amount The amount of Ether (in wei) to withdraw.
    function withdrawEther(uint256 amount) external onlyAuthorized nonReentrant {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Ether withdrawal failed");
        emit EtherWithdrawn(msg.sender, amount);
    }

    /// @notice Transfers ERC20 tokens from the wallet to a specified address.
    /// @param token The ERC20 token to transfer.
    /// @param to The recipient address.
    /// @param amount The amount of tokens to transfer.
    function transferToken(IERC20 token, address to, uint256 amount) external onlyAuthorized nonReentrant {
        require(address(token) != address(0), "Invalid token address");
        require(to != address(0), "Invalid recipient address");
        token.safeTransfer(to, amount);
        emit TokenTransferred(address(token), to, amount);
    }

    /// @notice Fallback function to receive Ether.
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @notice Fallback function for non-empty calldata.
    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }
}
