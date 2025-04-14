// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOracle {
    function getPrice() external view returns (uint256);
}

/// @title GasAccountingNEVM
/// @notice A simple VM that simulates gas consumption during execution.
/// Supported opcodes: PUSH, ADD, GET_PRICE, END.
contract GasAccountingNEVM {
    IOracle public oracle;
    uint constant MAX_STACK = 100;
    uint256 public constant OPCODE_COST = 50; // arbitrary gas cost per opcode (for simulation)

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
    }

    function executeProgram(bytes memory program, uint256 initialGas) external view returns (int256 result, uint256 remainingGas) {
        int256[MAX_STACK] memory stack;
        uint stackPtr = 0;
        uint i = 0;
        uint256 gasLeft = initialGas;
        
        while(i < program.length) {
            require(gasLeft >= OPCODE_COST, "Out of simulated gas");
            gasLeft -= OPCODE_COST;
            
            uint8 opcode = uint8(program[i]);
            i++;
            if (opcode == 0x01) { // PUSH
                require(i + 32 <= program.length, "PUSH: insufficient data");
                int256 value;
                assembly {
                    value := mload(add(program, add(32, i)))
                }
                require(stackPtr < MAX_STACK, "Stack overflow on PUSH");
                stack[stackPtr++] = value;
                i += 32;
            } else if (opcode == 0x02) { // ADD
                require(stackPtr >= 2, "Stack underflow on ADD");
                int256 a = stack[stackPtr - 1];
                int256 b = stack[stackPtr - 2];
                stackPtr -= 2;
                stack[stackPtr++] = a + b;
            } else if (opcode == 0x10) { // GET_PRICE
                uint256 price = oracle.getPrice();
                require(stackPtr < MAX_STACK, "Stack overflow on GET_PRICE");
                stack[stackPtr++] = int256(price);
            } else if (opcode == 0xFF) { // END
                break;
            } else {
                revert("Unknown opcode");
            }
        }
        require(stackPtr > 0, "Empty stack at end");
        result = stack[stackPtr - 1];
        remainingGas = gasLeft;
    }
}
