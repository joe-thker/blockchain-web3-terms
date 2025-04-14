// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOracle {
    function getPrice() external view returns (uint256);
}

/// @title ExtendedNEVM
/// @notice A stack-based VM with additional opcodes: exponentiation and modulo.
/// Opcodes:
/// 0x01: PUSH (next 32 bytes)
/// 0x02: ADD
/// 0x03: SUB
/// 0x04: MUL
/// 0x05: DIV
/// 0x06: EXP (exponentiation: second^top)
/// 0x07: MOD (modulo: second mod top)
/// 0x10: GET_PRICE
/// 0xFF: END
contract ExtendedNEVM {
    IOracle public oracle;
    uint constant MAX_STACK = 100;

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
    }

    function executeProgram(bytes memory program) external view returns (int256 result) {
        int256[MAX_STACK] memory stack;
        uint stackPtr = 0;
        uint i = 0;
        
        while (i < program.length) {
            uint8 opcode = uint8(program[i]);
            i++;
            if (opcode == 0x01) { // PUSH
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
                stack[stackPtr] = a + b;
                stackPtr++;
            } else if (opcode == 0x03) { // SUB (second - top)
                require(stackPtr >= 2, "Stack underflow on SUB");
                int256 a = stack[stackPtr - 1];
                int256 b = stack[stackPtr - 2];
                stackPtr -= 2;
                stack[stackPtr] = b - a;
                stackPtr++;
            } else if (opcode == 0x04) { // MUL
                require(stackPtr >= 2, "Stack underflow on MUL");
                int256 a = stack[stackPtr - 1];
                int256 b = stack[stackPtr - 2];
                stackPtr -= 2;
                stack[stackPtr] = a * b;
                stackPtr++;
            } else if (opcode == 0x05) { // DIV (second / top)
                require(stackPtr >= 2, "Stack underflow on DIV");
                int256 a = stack[stackPtr - 1];
                require(a != 0, "Division by zero");
                int256 b = stack[stackPtr - 2];
                stackPtr -= 2;
                stack[stackPtr] = b / a;
                stackPtr++;
            } else if (opcode == 0x06) { // EXP (exponentiation: second^top)
                require(stackPtr >= 2, "Stack underflow on EXP");
                int256 exponent = stack[stackPtr - 1];
                int256 base = stack[stackPtr - 2];
                stackPtr -= 2;
                int256 power = 1;
                // Very basic exponentiation loop (no overflow checks)
                for (int256 j = 0; j < exponent; j++) {
                    power *= base;
                }
                stack[stackPtr] = power;
                stackPtr++;
            } else if (opcode == 0x07) { // MOD (modulo: second mod top)
                require(stackPtr >= 2, "Stack underflow on MOD");
                int256 divisor = stack[stackPtr - 1];
                require(divisor != 0, "Division by zero in MOD");
                int256 dividend = stack[stackPtr - 2];
                stackPtr -= 2;
                stack[stackPtr] = dividend % divisor;
                stackPtr++;
            } else if (opcode == 0x10) { // GET_PRICE
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
