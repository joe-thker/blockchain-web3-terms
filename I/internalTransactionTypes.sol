// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title InternalTransactionTypes
/// @notice Demonstrates various types of internal transactions in Solidity

/// 1. Internal Function Call
contract InternalFunctionCall {
    event InternalCalled(uint256 result);

    function trigger() external {
        uint256 result = _computeInternal(5);
        emit InternalCalled(result);
    }

    function _computeInternal(uint256 x) internal pure returns (uint256) {
        return x * 2;
    }
}

/// 2. Call to Another Contract (Internal Message Call)
contract CalledContract {
    event Pinged(address from);

    function ping() external {
        emit Pinged(msg.sender);
    }
}

contract InternalCrossContractCall {
    CalledContract public called;

    constructor(address _called) {
        called = CalledContract(_called);
    }

    function callOther() external {
        called.ping(); // Internal call (via msg.sender contract)
    }
}

/// 3. Delegatecall (Preserves context, internal storage mutation)
contract DelegateLogic {
    uint256 public value;

    function setValue(uint256 _value) external {
        value = _value;
    }
}

contract DelegateProxy {
    address public impl;

    constructor(address _impl) {
        impl = _impl;
    }

    function delegateSetValue(uint256 _value) external {
        (bool success, ) = impl.delegatecall(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );
        require(success, "Delegatecall failed");
    }
}

/// 4. Fallback to Internal Execution (receive/ fallback)
contract InternalFallbackRouter {
    event Received(address sender, uint256 amount);

    receive() external payable {
        _handleReceive(msg.sender, msg.value);
    }

    fallback() external payable {
        _handleReceive(msg.sender, msg.value);
    }

    function _handleReceive(address sender, uint256 value) internal {
        emit Received(sender, value);
    }
}

/// 5. Recursive Internal Call
contract RecursiveInternal {
    event DepthReached(uint256 depth);

    function start(uint256 depth) external {
        _recurse(depth);
    }

    function _recurse(uint256 n) internal {
        if (n == 0) {
            emit DepthReached(n);
            return;
        }
        _recurse(n - 1);
    }
}
