// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IOracle
/// @notice A simple oracle interface that returns a token price scaled by 1e18.
interface IOracle {
    function getPrice() external view returns (uint256);
}

/// @title BasicNEVM
/// @notice A simple stack-based virtual machine with oracle integration.
/// Supported opcodes:
/// - 0x01: PUSH (push 32-byte constant)
/// - 0x02: ADD (pop two values, push sum)
/// - 0x03: SUB (pop two values, compute second minus first)
/// - 0x04: MUL (pop two values, push product)
/// - 0x05: DIV (pop two values, push second / first; divisor must be nonzero)
/// - 0x10: GET_PRICE (push oracle price onto the stack)
/// - 0xFF: END (terminate execution)
contract BasicNEVM {
    IOracle public oracle;
    uint constant MAX_STACK = 100; // maximum stack depth

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
    }

    /// @notice Executes a program (bytecode) and returns the top-of-stack result.
    /// @param program The byte array containing the program.
    /// @return result The result on the top of the stack.
    function executeProgram(bytes memory program) external view returns (int256 result) {
        int256[MAX_STACK] memory stack;
        uint stackPtr = 0;
        uint i = 0;
        
        while (i < program.length) {
            uint8 opcode = uint8(program[i]);
            i++;
            if (opcode == 0x01) { // PUSH: Next 32 bytes: int256 constant
                require(i + 32 <= program.length, "PUSH: insufficient data");
                int256 value;
                assembly {
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
            } else if (opcode == 0x03) { // SUB (second - top)
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
            } else if (opcode == 0x05) { // DIV (second / top)
                require(stackPtr >= 2, "Stack underflow on DIV");
                int256 a = stack[stackPtr - 1];
                require(a != 0, "Division by zero");
                int256 b = stack[stackPtr - 2];
                stackPtr -= 2;
                require(stackPtr < MAX_STACK, "Stack overflow on DIV result");
                stack[stackPtr] = b / a;
                stackPtr++;
            } else if (opcode == 0x10) { // GET_PRICE: oracle price
                uint256 price = oracle.getPrice();
                require(stackPtr < MAX_STACK, "Stack overflow on GET_PRICE");
                stack[stackPtr] = int256(price);
                stackPtr++;
            } else if (opcode == 0xFF) { // END
                break;
            } else {
                revert("Unknown opcode");
            }
        }
        require(stackPtr > 0, "Empty stack at end");
        result = stack[stackPtr - 1];
    }
}
