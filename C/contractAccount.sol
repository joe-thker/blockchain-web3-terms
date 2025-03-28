// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ContractAccount
/// @notice This contract serves as a smart wallet (contract account) that holds Ether and
/// allows the owner or additional authorized addresses to execute arbitrary calls and withdraw funds.
/// The design is dynamic (authorization can be updated), optimized (minimal state), and secure (access control and reentrancy protection).
contract ContractAccount is Ownable, ReentrancyGuard {
    // Mapping to store additional authorized addresses.
    mapping(address => bool) public authorized;

    /// @notice Emitted when an authorized address is added.
    event AuthorizedAdded(address indexed account);
    /// @notice Emitted when an authorized address is removed.
    event AuthorizedRemoved(address indexed account);
    /// @notice Emitted when an execution call is made.
    event Executed(address indexed target, uint256 value, bytes data, bytes result);
    /// @notice Emitted when funds are withdrawn.
    event Withdrawn(address indexed to, uint256 amount);
    /// @notice Emitted when Ether is received.
    event Received(address indexed sender, uint256 amount);

    /// @notice Modifier to restrict functions to only the owner or authorized addresses.
    modifier onlyAuthorized() {
        require(msg.sender == owner() || authorized[msg.sender], "Not authorized");
        _;
    }

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {
        // Additional authorized addresses can be added later by the owner.
    }

    /// @notice Allows the owner to add an authorized address.
    /// @param account The address to add.
    function addAuthorized(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
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

    /// @notice Executes an arbitrary call from this contract.
    /// @param target The target address to call.
    /// @param value The amount of Ether (in wei) to send.
    /// @param data The calldata for the call.
    /// @return result The returned data from the call.
    function execute(address target, uint256 value, bytes calldata data)
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

    /// @notice Allows an authorized address or owner to withdraw Ether from the contract.
    /// @param amount The amount of Ether (in wei) to withdraw.
    function withdraw(uint256 amount) external onlyAuthorized nonReentrant {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
        emit Withdrawn(msg.sender, amount);
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
