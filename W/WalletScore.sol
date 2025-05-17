// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title WalletScoreRegistry - Stores and verifies wallet score submissions
contract WalletScoreRegistry {
    address public immutable scoreOracle;
    mapping(address => uint256) public walletScore;
    mapping(bytes32 => bool) public usedDigests;

    event ScoreUpdated(address indexed wallet, uint256 newScore);

    constructor(address _oracle) {
        scoreOracle = _oracle;
    }

    function submitScore(
        address wallet,
        uint256 score,
        uint256 nonce,
        bytes calldata signature
    ) external {
        bytes32 digest = keccak256(abi.encodePacked(wallet, score, nonce, address(this)));
        require(!usedDigests[digest], "Replay detected");
        require(recover(digest, signature) == scoreOracle, "Invalid oracle sig");

        walletScore[wallet] = score;
        usedDigests[digest] = true;

        emit ScoreUpdated(wallet, score);
    }

    function getScore(address wallet) external view returns (uint256) {
        return walletScore[wallet];
    }

    function recover(bytes32 digest, bytes memory sig) public pure returns (address) {
        require(sig.length == 65, "Bad sig");
        bytes32 r; bytes32 s; uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return ecrecover(digest, v, r, s);
    }
}
