// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TwoFactorWallet - Dual-signer wallet simulating 2FA on-chain
contract TwoFactorWallet {
    address public primary;
    address public secondary;

    mapping(bytes32 => bool) public usedTx;

    event Executed(address indexed to, uint256 value, bytes data);

    constructor(address _primary, address _secondary) {
        primary = _primary;
        secondary = _secondary;
    }

    /// @notice Execute a protected call (2 signatures required)
    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata sig
    ) external {
        require(msg.sender == primary, "Only primary");
        bytes32 txHash = getTxHash(to, value, data);
        require(!usedTx[txHash], "Already used");

        require(_verify(txHash, sig, secondary), "2FA sig invalid");

        usedTx[txHash] = true;
        (bool ok, ) = to.call{value: value}(data);
        require(ok, "Execution failed");

        emit Executed(to, value, data);
    }

    function getTxHash(address to, uint256 value, bytes calldata data) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(to, value, data));
    }

    function _verify(bytes32 hash, bytes calldata sig, address signer) internal pure returns (bool) {
        (uint8 v, bytes32 r, bytes32 s) = split(sig);
        bytes32 ethMsg = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return ecrecover(ethMsg, v, r, s) == signer;
    }

    function split(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "Invalid sig");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    receive() external payable {}
}
