// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FIFOQueueBytes32
 * @dev A simple FIFO queue for storing bytes32 values.
 */
contract FIFOQueueBytes32 {
    uint256 private front;
    uint256 private rear;
    mapping(uint256 => bytes32) private queue;

    constructor() {
        front = 1;
        rear = 0;
    }

    /**
     * @dev Enqueues a bytes32 value.
     * @param item The bytes32 value to store in the queue.
     */
    function enqueue(bytes32 item) public {
        require(item != bytes32(0), "Cannot enqueue zero value");
        rear++;
        queue[rear] = item;
    }

    /**
     * @dev Dequeues the first bytes32 value.
     * @return The dequeued bytes32 value.
     */
    function dequeue() public returns (bytes32) {
        require(!isEmpty(), "Queue is empty");
        bytes32 item = queue[front];
        delete queue[front];
        front++;
        return item;
    }

    /**
     * @dev Peeks at the first bytes32 value without removing it.
     * @return The bytes32 value at the front.
     */
    function peek() public view returns (bytes32) {
        require(!isEmpty(), "Queue is empty");
        return queue[front];
    }

    /**
     * @dev Checks if the queue is empty.
     * @return True if the queue is empty; otherwise, false.
     */
    function isEmpty() public view returns (bool) {
        return front > rear;
    }

    /**
     * @dev Returns the size of the queue.
     * @return The number of elements in the queue.
     */
    function size() public view returns (uint256) {
        if (isEmpty()) return 0;
        return rear - front + 1;
    }
}
