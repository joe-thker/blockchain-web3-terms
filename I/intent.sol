// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title IntentSettlement
/// @notice Executes off-chain signed user intents (e.g., token swaps)
contract IntentSettlement {
    using ECDSA for bytes32; // ✅ Enable .toEthSignedMessageHash()

    event IntentExecuted(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    struct SwapIntent {
        address user;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minOut;
        uint256 deadline;
    }

    constructor() {}

    /// @notice Hash the user's intent message
    function hashIntent(SwapIntent memory intent) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            intent.user,
            intent.tokenIn,
            intent.tokenOut,
            intent.amountIn,
            intent.minOut,
            intent.deadline
        ));
    }

    /// @notice Execute a signed intent if valid and within time
    function executeIntent(SwapIntent calldata intent, bytes calldata signature) external {
        require(block.timestamp <= intent.deadline, "Intent expired");

        bytes32 digest = hashIntent(intent).toEthSignedMessageHash(); // ✅ Correct usage
        address recovered = digest.recover(signature);
        require(recovered == intent.user, "Invalid signature");

        // Simulate a swap
        IERC20(intent.tokenIn).transferFrom(intent.user, address(this), intent.amountIn);
        IERC20(intent.tokenOut).transfer(intent.user, intent.minOut);

        emit IntentExecuted(
            intent.user,
            intent.tokenIn,
            intent.tokenOut,
            intent.amountIn,
            intent.minOut
        );
    }
}
