// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IERC20 Interface
/// @notice Minimal interface for interacting with an ERC-20 token.
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

/// @title SimpleBridge
/// @notice A simple simulation of a blockchain bridge for locking tokens on one chain and releasing them on another.
/// @dev This contract does not implement full cross-chain messaging but demonstrates basic deposit (lock) and withdrawal (release) mechanisms.
contract SimpleBridge {
    address public admin;
    IERC20 public token;

    // Mapping to track the amount of tokens locked by each user.
    mapping(address => uint256) public lockedBalance;

    // Events for deposit and withdrawal actions.
    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 timestamp);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    /// @notice Constructor sets the contract deployer as the admin and defines the token to be bridged.
    /// @param _token The address of the ERC-20 token that will be used in the bridge.
    constructor(address _token) {
        admin = msg.sender;
        token = IERC20(_token);
    }

    /// @notice Deposits tokens to the bridge, locking them on the source chain.
    /// @param amount The amount of tokens to deposit.
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        lockedBalance[msg.sender] += amount;
        emit Deposited(msg.sender, amount, block.timestamp);
    }

    /// @notice Withdraws tokens from the bridge for a user.
    /// @dev Only the admin (bridge operator) can trigger withdrawals.
    /// @param user The address of the user to withdraw tokens for.
    /// @param amount The amount of tokens to withdraw.
    function withdraw(address user, uint256 amount) external onlyAdmin {
        require(lockedBalance[user] >= amount, "Insufficient locked balance");
        lockedBalance[user] -= amount;
        require(token.transfer(user, amount), "Token transfer failed");
        emit Withdrawn(user, amount, block.timestamp);
    }
}
