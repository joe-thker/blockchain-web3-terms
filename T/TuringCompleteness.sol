// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TuringCompleteExample - Demonstrates Turing-complete features in Solidity

contract TuringCompleteExample {
    /// 🔁 Dynamic loop with conditional branching
    function sumEvenNumbers(uint256[] memory input) public pure returns (uint256 sum) {
        for (uint256 i = 0; i < input.length; i++) {
            if (input[i] % 2 == 0) {
                sum += input[i];
            }
        }
    }

    /// 🔂 Recursive function (factorial) - limited depth
    function factorial(uint256 n) public pure returns (uint256) {
        require(n <= 20, "Depth limit to prevent gas blowup"); // Safe cap
        if (n == 0 || n == 1) return 1;
        return n * factorial(n - 1);
    }

    /// 🔄 Simulate a state machine using enums
    enum State {Init, Active, Closed}
    State public current;

    function activate() external {
        require(current == State.Init, "Wrong state");
        current = State.Active;
    }

    function close() external {
        require(current == State.Active, "Must be active first");
        current = State.Closed;
    }

    function reset() external {
        require(current == State.Closed, "Must be closed");
        current = State.Init;
    }
}
