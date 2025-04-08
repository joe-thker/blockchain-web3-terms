// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FIFOQueueAddress
 * @dev A simple FIFO (First In, First Out) queue for storing addresses.
 */
contract FIFOQueueAddress {
    // Indices for managing the queue.
    uint256 private front; // index for next element to dequeue
    uint256 private rear;  // index of the last element enqueued

    // Mapping to hold the queued addresses.
    mapping(uint256 => address) private queue;

    /**
     * @dev Constructor initializes the queue indices.
     */
    constructor() {
        // Start front at 1 and rear at 0 so the first enqueued element will be at position 1.
        front = 1;
        rear = 0;
    }

    /**
     * @dev Enqueues an address into the queue.
     * @param item The address to add.
     */
    function enqueue(address item) public {
        require(item != address(0), "Cannot enqueue zero address");
        rear++;
        queue[rear] = item;
    }

    /**
     * @dev Dequeues the first address from the queue.
     * @return item The dequeued address.
     */
    function dequeue() public returns (address item) {
        require(!isEmpty(), "Queue is empty");
        item = queue[front];
        delete queue[front];
        front++;
        return item;
    }

    /**
     * @dev Peeks at the address at the front of the queue without removing it.
     * @return The address at the front.
     */
    function peek() public view returns (address) {
        require(!isEmpty(), "Queue is empty");
        return queue[front];
    }

    /**
     * @dev Checks whether the queue is empty.
     * @return True if empty, otherwise false.
     */
    function isEmpty() public view returns (bool) {
        return front > rear;
    }

    /**
     * @dev Returns the current number of elements in the queue.
     * @return The size of the queue.
     */
    function size() public view returns (uint256) {
        if (isEmpty()) return 0;
        return rear - front + 1;
    }
}
