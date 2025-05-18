// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title WebSocketEventEmitter - Emits real-time onchain events for Web3 subscribers
contract WebSocketEventEmitter {
    address public immutable admin;

    enum ActionType {
        Mint,
        Purchase,
        Vote,
        Stake,
        Unstake,
        Custom
    }

    struct EventLog {
        ActionType action;
        string description;
        uint256 timestamp;
    }

    mapping(address => EventLog[]) public userHistory;
    mapping(ActionType => uint256) public totalActions;

    event ActionBroadcast(
        address indexed user,
        ActionType indexed actionType,
        string description,
        uint256 timestamp
    );

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /// @notice Broadcast a user action with typed description
    function broadcastAction(ActionType action, string calldata description) external {
        EventLog memory log = EventLog({
            action: action,
            description: description,
            timestamp: block.timestamp
        });

        userHistory[msg.sender].push(log);
        totalActions[action]++;

        emit ActionBroadcast(msg.sender, action, description, block.timestamp);
    }

    /// @notice Admin can emit a signal without storing user history
    function adminSignal(address user, ActionType action, string calldata note) external onlyAdmin {
        emit ActionBroadcast(user, action, note, block.timestamp);
    }

    /// @notice Get total actions logged for a given user
    function getUserActionCount(address user) external view returns (uint256) {
        return userHistory[user].length;
    }

    /// @notice Get full user event history
    function getUserEvents(address user) external view returns (EventLog[] memory) {
        return userHistory[user];
    }

    /// @notice Get total number of specific action type across all users
    function getTotalAction(ActionType action) external view returns (uint256) {
        return totalActions[action];
    }
}
