// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FIFOQueueUint
 * @dev A simple FIFO queue for unsigned integers.
 */
contract FIFOQueueUint {
    uint256 private front;
    uint256 private rear;
    mapping(uint256 => uint256) private queue;

    constructor() {
        front = 1;
        rear = 0;
    }

    /**
     * @dev Enqueues a uint256 value into the queue.
     * @param item The value to enqueue.
     */
    function enqueue(uint256 item) public {
        rear++;
        queue[rear] = item;
    }

    /**
     * @dev Dequeues the first uint256 value from the queue.
     * @return The dequeued value.
     */
    function dequeue() public returns (uint256) {
        require(!isEmpty(), "Queue is empty");
        uint256 item = queue[front];
        delete queue[front];
        front++;
        return item;
    }

    /**
     * @dev Peeks at the first uint256 value without removing it.
     * @return The value at the front.
     */
    function peek() public view returns (uint256) {
        require(!isEmpty(), "Queue is empty");
        return queue[front];
    }

    /**
     * @dev Checks whether the queue is empty.
     * @return True if empty; otherwise, false.
     */
    function isEmpty() public view returns (bool) {
        return front > rear;
    }

    /**
     * @dev Returns the current size of the queue.
     * @return The number of elements in the queue.
     */
    function size() public view returns (uint256) {
        if (isEmpty()) return 0;
        return rear - front + 1;
    }
}
