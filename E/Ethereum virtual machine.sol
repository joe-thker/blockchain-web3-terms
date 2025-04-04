// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EthereumVirtualMachineDemo {
    uint256 private storedValue;

    event GasLeft(uint256 gas);
    event RawCallResult(bool success, bytes data);
    event StoredViaAssembly(uint256 value);

    // ========== 1. Use EVM's gasleft() ==========
    function checkGas() external {
        uint256 remaining = gasleft();
        emit GasLeft(remaining);
    }

    // ========== 2. Store a value using inline assembly (SSTORE) ==========
    function storeWithAssembly(uint256 _value) external {
        assembly {
            sstore(0, _value) // store _value at slot 0
        }
        emit StoredViaAssembly(_value);
    }

    // ========== 3. Retrieve value using SLOAD via Assembly ==========
    function loadWithAssembly() external view returns (uint256 val) {
        assembly {
            val := sload(0)
        }
    }

    // ========== 4. Low-level CALL using EVM ==========
    function rawCall(address target, bytes calldata data) external {
        (bool success, bytes memory result) = target.call(data);
        emit RawCallResult(success, result);
    }

    // ========== 5. Get EVM globals ==========
    function getEnv() external view returns (
        address sender,
        uint256 gasLimit,
        uint256 blockNum,
        uint256 timestamp,
        uint256 chainId
    ) {
        sender = msg.sender;
        gasLimit = block.gaslimit;
        blockNum = block.number;
        timestamp = block.timestamp;
        assembly {
            chainId := chainid()
        }
    }
}
