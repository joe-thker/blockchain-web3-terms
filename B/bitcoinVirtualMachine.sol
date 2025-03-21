// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BitcoinVirtualMachine {
    // Define opcodes as constants
    uint8 constant OPCODE_PUSH   = 0;
    uint8 constant OPCODE_ADD    = 1;
    uint8 constant OPCODE_EQUAL  = 2;
    uint8 constant OPCODE_VERIFY = 3;

    // Instruction structure: each instruction has an opcode and an optional operand.
    struct Instruction {
        uint8 opcode;
        uint256 operand; // Used only for PUSH; ignored for other opcodes.
    }

    // Event to log the final stack state after program execution.
    event ProgramExecuted(uint256[] finalStack);

    /// @notice Executes a program (array of instructions) on the virtual machine.
    /// @param program An array of Instruction structs representing the program.
    /// @return finalStack The final stack state after execution.
    function runProgram(Instruction[] memory program) public returns (uint256[] memory finalStack) {
        // Use a dynamic array to simulate the stack.
        uint256[] memory tempStack = new uint256[](program.length); // Maximum possible size.
        uint256 stackSize = 0;

        // Process each instruction in the program.
        for (uint256 i = 0; i < program.length; i++) {
            Instruction memory inst = program[i];
            if (inst.opcode == OPCODE_PUSH) {
                // Push operand onto the stack.
                tempStack[stackSize] = inst.operand;
                stackSize++;
            } else if (inst.opcode == OPCODE_ADD) {
                require(stackSize >= 2, "ADD requires at least 2 stack items");
                uint256 a = tempStack[stackSize - 1];
                uint256 b = tempStack[stackSize - 2];
                stackSize -= 2;
                uint256 sum = a + b;
                tempStack[stackSize] = sum;
                stackSize++;
            } else if (inst.opcode == OPCODE_EQUAL) {
                require(stackSize >= 2, "EQUAL requires at least 2 stack items");
                uint256 a = tempStack[stackSize - 1];
                uint256 b = tempStack[stackSize - 2];
                stackSize -= 2;
                uint256 result = (a == b) ? 1 : 0;
                tempStack[stackSize] = result;
                stackSize++;
            } else if (inst.opcode == OPCODE_VERIFY) {
                require(stackSize >= 1, "VERIFY requires at least 1 stack item");
                uint256 value = tempStack[stackSize - 1];
                stackSize--; // Pop the value.
                require(value == 1, "VERIFY failed");
            } else {
                revert("Unknown opcode");
            }
        }

        // Prepare final stack array of the correct size.
        finalStack = new uint256[](stackSize);
        for (uint256 j = 0; j < stackSize; j++) {
            finalStack[j] = tempStack[j];
        }

        emit ProgramExecuted(finalStack);
        return finalStack;
    }
}
