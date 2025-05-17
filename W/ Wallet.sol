// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SimpleSmartWallet - Smart wallet with owner, EIP-1271 support, and execution
contract SimpleSmartWallet {
    address public owner;
    uint256 public nonce;

    event Executed(address target, uint256 value, bytes data);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function execute(address target, uint256 value, bytes calldata data) external onlyOwner {
        (bool ok, ) = target.call{value: value}(data);
        require(ok, "Execution failed");
        emit Executed(target, value, data);
    }

    // EIP-1271: isValidSignature for contract-based accounts
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4) {
        require(recover(hash, signature) == owner, "Invalid signature");
        return 0x1626ba7e; // magic value for EIP-1271
    }

    function recover(bytes32 hash, bytes memory sig) public pure returns (address) {
        require(sig.length == 65, "Invalid sig");
        bytes32 r; bytes32 s; uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return ecrecover(hash, v, r, s);
    }

    receive() external payable {}
}
