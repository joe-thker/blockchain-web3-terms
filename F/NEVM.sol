// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IOracle
/// @notice A simple oracle interface that returns a token price scaled by 1e18.
interface IOracle {
    function getPrice() external view returns (uint256);
}

/// @title NetworkEnhancedVM
/// @notice A simple stack-based virtual machine with network enhancement (oracle integration).
///         Supported opcodes:
///           0x01: PUSH — Push a 32-byte (int256) constant onto the stack.
///           0x02: ADD  — Pop two values, add them, and push the result.
///           0x03: SUB  — Pop two values, subtract (second minus first), and push the result.
///           0x04: MUL  — Pop two values, multiply, and push the result.
///           0x05: DIV  — Pop two values, divide (second divided by first), and push the result.
///           0x10: GET_PRICE — Fetch a price from the oracle and push it onto the stack.
///           0xFF: END  — Terminate the program.
contract NetworkEnhancedVM {
    IOracle public oracle;
    uint constant MAX_STACK = 100; // maximum stack depth

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
    }

    /// @notice Execute a program (bytecode) and return the top of the stack as the result.
    /// @param program The byte array containing the program.
    /// @return result The final result from the top of the stack.
    function executeProgram(bytes memory program) external view returns (int256 result) {
        // Fixed-size stack (array of int256)
        int256[MAX_STACK] memory stack;
        uint stackPtr = 0;
        uint i = 0;
        
        while (i < program.length) {
            uint8 opcode = uint8(program[i]);
            i++;
            if (opcode == 0x01) { // PUSH: next 32 bytes are the constant
                require(i + 32 <= program.length, "PUSH: Not enough data");
                int256 value;
                assembly {
                    // mload loads 32 bytes from memory location: add(program, add(32, i))
                    value := mload(add(program, add(32, i)))
                }
                require(stackPtr < MAX_STACK, "Stack overflow on PUSH");
                stack[stackPtr] = value;
                stackPtr++;
                i += 32;
            } else if (opcode == 0x02) { // ADD
                require(stackPtr >= 2, "Stack underflow on ADD");
                int256 a = stack[stackPtr - 1];
                int256 b = stack[stackPtr - 2];
                stackPtr -= 2;
                require(stackPtr < MAX_STACK, "Stack overflow on ADD result");
                stack[stackPtr] = a + b;
                stackPtr++;
            } else if (opcode == 0x03) { // SUB: second minus top
                require(stackPtr >= 2, "Stack underflow on SUB");
                int256 a = stack[stackPtr - 1];
                int256 b = stack[stackPtr - 2];
                stackPtr -= 2;
                require(stackPtr < MAX_STACK, "Stack overflow on SUB result");
                stack[stackPtr] = b - a;
                stackPtr++;
            } else if (opcode == 0x04) { // MUL
                require(stackPtr >= 2, "Stack underflow on MUL");
                int256 a = stack[stackPtr - 1];
                int256 b = stack[stackPtr - 2];
                stackPtr -= 2;
                require(stackPtr < MAX_STACK, "Stack overflow on MUL result");
                stack[stackPtr] = a * b;
                stackPtr++;
            } else if (opcode == 0x05) { // DIV: second divided by top
                require(stackPtr >= 2, "Stack underflow on DIV");
                int256 a = stack[stackPtr - 1];
                require(a != 0, "Division by zero");
                int256 b = stack[stackPtr - 2];
                stackPtr -= 2;
                require(stackPtr < MAX_STACK, "Stack overflow on DIV result");
                stack[stackPtr] = b / a;
                stackPtr++;
            } else if (opcode == 0x10) { // GET_PRICE: fetch oracle price
                uint256 price = oracle.getPrice();
                require(stackPtr < MAX_STACK, "Stack overflow on GET_PRICE");
                stack[stackPtr] = int256(price);
                stackPtr++;
            } else if (opcode == 0xFF) { // END: terminate execution
                break;
            } else {
                revert("Unknown opcode");
            }
        }
        require(stackPtr > 0, "Empty stack at end");
        result = stack[stackPtr - 1];
    }
}
