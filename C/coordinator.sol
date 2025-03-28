// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Coordinator
/// @notice This contract manages scheduled tasks. The owner can create, update, cancel,
/// and execute tasks once their scheduled time has been reached. Tasks are stored in a mapping,
/// and each is given a unique ID. This design is dynamic (tasks can be managed on the fly),
/// optimized (minimal storage usage and gas-efficient operations), and secure (access control and reentrancy protection).
contract Coordinator is Ownable, ReentrancyGuard {
    // Structure representing a task.
    struct Task {
        uint256 id;
        string description;
        address target;
        bytes data;
        uint256 scheduledTime;
        bool executed;
        bool cancelled;
    }
    
    // Incremental task ID counter.
    uint256 public nextTaskId;
    // Mapping from task ID to Task details.
    mapping(uint256 => Task) public tasks;
    
    // --- Events ---
    event TaskCreated(uint256 indexed taskId, string description, address indexed target, uint256 scheduledTime);
    event TaskUpdated(uint256 indexed taskId, string description, address indexed target, uint256 scheduledTime);
    event TaskCancelled(uint256 indexed taskId);
    event TaskExecuted(uint256 indexed taskId, bytes result);

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {
        // No additional initialization required.
    }
    
    /// @notice Creates a new task to be executed at or after the specified scheduled time.
    /// @param _description A description of the task.
    /// @param _target The target address that will be called when the task is executed.
    /// @param _data The call data for the task.
    /// @param _scheduledTime The earliest time (timestamp) at which the task can be executed.
    /// @return taskId The unique ID assigned to the new task.
    function createTask(
        string calldata _description,
        address _target,
        bytes calldata _data,
        uint256 _scheduledTime
    ) external onlyOwner returns (uint256 taskId) {
        require(_target != address(0), "Invalid target");
        require(_scheduledTime >= block.timestamp, "Scheduled time must be in the future");

        taskId = nextTaskId;
        nextTaskId++;

        tasks[taskId] = Task({
            id: taskId,
            description: _description,
            target: _target,
            data: _data,
            scheduledTime: _scheduledTime,
            executed: false,
            cancelled: false
        });

        emit TaskCreated(taskId, _description, _target, _scheduledTime);
    }
    
    /// @notice Updates an existing task. Only tasks that are not yet executed or cancelled can be updated.
    /// @param taskId The ID of the task to update.
    /// @param _description The new description.
    /// @param _target The new target address.
    /// @param _data The new call data.
    /// @param _scheduledTime The new scheduled execution time.
    function updateTask(
        uint256 taskId,
        string calldata _description,
        address _target,
        bytes calldata _data,
        uint256 _scheduledTime
    ) external onlyOwner {
        Task storage task = tasks[taskId];
        require(task.id == taskId, "Task does not exist");
        require(!task.executed, "Task already executed");
        require(!task.cancelled, "Task cancelled");
        require(_target != address(0), "Invalid target");
        require(_scheduledTime >= block.timestamp, "Scheduled time must be in the future");

        task.description = _description;
        task.target = _target;
        task.data = _data;
        task.scheduledTime = _scheduledTime;
        
        emit TaskUpdated(taskId, _description, _target, _scheduledTime);
    }
    
    /// @notice Cancels a task that has not yet been executed.
    /// @param taskId The ID of the task to cancel.
    function cancelTask(uint256 taskId) external onlyOwner {
        Task storage task = tasks[taskId];
        require(task.id == taskId, "Task does not exist");
        require(!task.executed, "Task already executed");
        require(!task.cancelled, "Task already cancelled");
        
        task.cancelled = true;
        emit TaskCancelled(taskId);
    }
    
    /// @notice Executes a task if its scheduled time has been reached and it is not cancelled.
    /// @param taskId The ID of the task to execute.
    /// @return result The return data from the task execution.
    function executeTask(uint256 taskId) external onlyOwner nonReentrant returns (bytes memory result) {
        Task storage task = tasks[taskId];
        require(task.id == taskId, "Task does not exist");
        require(!task.executed, "Task already executed");
        require(!task.cancelled, "Task cancelled");
        require(block.timestamp >= task.scheduledTime, "Task not yet scheduled");

        task.executed = true;
        (bool success, bytes memory res) = task.target.call(task.data);
        require(success, "Task execution failed");
        result = res;
        
        emit TaskExecuted(taskId, result);
    }
}
