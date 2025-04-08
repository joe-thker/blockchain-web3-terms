// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FIFOQueue
 * @dev A simple FIFO (First In, First Out) queue that stores addresses.
 *
 * The contract uses two indices: `front` and `rear` to keep track of the queue's
 * head and tail. When an address is enqueued, it is stored at index `rear + 1`
 * and the `rear` is incremented. When an address is dequeued, the element at `front`
 * is removed and the `front` is incremented.
 */
contract FIFOQueue {
    // Queue indices: front points to the next element to dequeue; rear is the last enqueued element.
    uint256 private front;
    uint256 private rear;
    
    // Mapping to store queue elements.
    mapping(uint256 => address) private queue;

    // Events for enqueue and dequeue operations.
    event Enqueued(address indexed item);
    event Dequeued(address indexed item);

    /**
     * @dev The constructor initializes the queue indices.
     */
    constructor() {
        // We'll start front at 1 and rear at 0 so that when the first element is enqueued, rear becomes 1.
        front = 1;
        rear = 0;
    }

    /**
     * @dev Enqueues an address into the queue.
     * @param item The address to enqueue.
     */
    function enqueue(address item) public {
        require(item != address(0), "Cannot enqueue zero address");
        rear++;
        queue[rear] = item;
        emit Enqueued(item);
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
        emit Dequeued(item);
    }

    /**
     * @dev Returns the address at the front of the queue without removing it.
     * @return The address at the front of the queue.
     */
    function peek() public view returns (address) {
        require(!isEmpty(), "Queue is empty");
        return queue[front];
    }

    /**
     * @dev Checks whether the queue is empty.
     * @return True if the queue is empty; otherwise, false.
     */
    function isEmpty() public view returns (bool) {
        return front > rear;
    }

    /**
     * @dev Returns the number of elements in the queue.
     * @return The current size of the queue.
     */
    function size() public view returns (uint256) {
        if (isEmpty()) return 0;
        return rear - front + 1;
    }
}
