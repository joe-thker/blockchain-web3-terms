// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract StatefulNEVM {
    // Define opcodes for the VM:
    uint8 constant OP_PUSH  = 0x01;
    uint8 constant OP_ADD   = 0x02;
    uint8 constant OP_SUB   = 0x03;
    uint8 constant OP_MUL   = 0x04;
    uint8 constant OP_DIV   = 0x05;
    uint8 constant OP_STORE = 0x20;  // STORE: pop value and store it at memoryStorage[key]
    uint8 constant OP_LOAD  = 0x21;  // LOAD: push memoryStorage[key] onto the stack
    uint8 constant OP_END   = 0xFF;

    uint constant MAX_STACK = 100;

    // State storage for the VM (persistent)
    mapping(uint256 => int256) public memoryStorage;

    /// @notice Executes a program (provided as bytecode) and returns the final stack top value.
    /// This function is stateful because it uses the STORE opcode to write to contract storage.
    /// @param program The byte array representing the program.
    /// @return result The result from the top of the stack after execution.
    function executeProgram(bytes memory program) external returns (int256 result) {
        int256[MAX_STACK] memory stack;
        uint stackPtr = 0;
        uint i = 0;
        
        while (i < program.length) {
            uint8 opcode = uint8(program[i]);
            i++;
            if (opcode == OP_PUSH) { // PUSH: next 32 bytes represent int256 constant.
                require(i + 32 <= program.length, "PUSH: insufficient data");
                int256 value;
                assembly {
                    value := mload(add(program, add(32, i)))
                }
                require(stackPtr < MAX_STACK, "Stack overflow on PUSH");
                stack[stackPtr] = value;
                stackPtr++;
                i += 32;
            } else if (opcode == OP_ADD) {
                require(stackPtr >= 2, "ADD: Stack underflow");
                int256 a = stack[stackPtr - 1];
                int256 b = stack[stackPtr - 2];
                stackPtr -= 2;
                require(stackPtr < MAX_STACK, "Stack overflow on ADD result");
                stack[stackPtr] = a + b;
                stackPtr++;
            } else if (opcode == OP_SUB) { // SUB: (second - top)
                require(stackPtr >= 2, "SUB: Stack underflow");
                int256 a = stack[stackPtr - 1];
                int256 b = stack[stackPtr - 2];
                stackPtr -= 2;
                require(stackPtr < MAX_STACK, "Stack overflow on SUB result");
                stack[stackPtr] = b - a;
                stackPtr++;
            } else if (opcode == OP_MUL) {
                require(stackPtr >= 2, "MUL: Stack underflow");
                int256 a = stack[stackPtr - 1];
                int256 b = stack[stackPtr - 2];
                stackPtr -= 2;
                require(stackPtr < MAX_STACK, "Stack overflow on MUL result");
                stack[stackPtr] = a * b;
                stackPtr++;
            } else if (opcode == OP_DIV) { // DIV: (second divided by top)
                require(stackPtr >= 2, "DIV: Stack underflow");
                int256 a = stack[stackPtr - 1];
                require(a != 0, "DIV: Division by zero");
                int256 b = stack[stackPtr - 2];
                stackPtr -= 2;
                require(stackPtr < MAX_STACK, "Stack overflow on DIV result");
                stack[stackPtr] = b / a;
                stackPtr++;
            } else if (opcode == OP_STORE) {
                // Next 32 bytes represent the memory key (as uint256).
                require(i + 32 <= program.length, "STORE: insufficient key data");
                uint256 key;
                assembly {
                    key := mload(add(program, add(32, i)))
                }
                i += 32;
                require(stackPtr >= 1, "STORE: Stack underflow");
                int256 value = stack[stackPtr - 1];
                stackPtr--;
                // Write the value to state storage.
                memoryStorage[key] = value;
            } else if (opcode == OP_LOAD) {
                // Next 32 bytes represent the memory key.
                require(i + 32 <= program.length, "LOAD: insufficient key data");
                uint256 key;
                assembly {
                    key := mload(add(program, add(32, i)))
                }
                i += 32;
                int256 value = memoryStorage[key];
                require(stackPtr < MAX_STACK, "LOAD: Stack overflow");
                stack[stackPtr] = value;
                stackPtr++;
            } else if (opcode == OP_END) {
                break;
            } else {
                revert("Unknown opcode");
            }
        }
        require(stackPtr > 0, "Empty stack at end");
        result = stack[stackPtr - 1];
    }
}
