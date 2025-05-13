// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TRC10BridgeReceiver - Accepts Proof of TRC-10 Transfer and Mints Wrapped ERC20

interface IBridgeValidator {
    function verifyTRC10Proof(bytes calldata proof) external view returns (address sender, uint256 amount, uint256 assetId);
}

contract TRC10BridgeReceiver {
    address public validator;
    mapping(bytes32 => bool) public processedProofs;
    mapping(uint256 => address) public assetToERC20;

    event Wrapped(address indexed user, uint256 assetId, uint256 amount);

    constructor(address _validator) {
        validator = _validator;
    }

    function registerAsset(uint256 assetId, address erc20Token) external {
        assetToERC20[assetId] = erc20Token;
    }

    function submitProof(bytes calldata proof) external {
        (address sender, uint256 amt, uint256 assetId) = IBridgeValidator(validator).verifyTRC10Proof(proof);
        bytes32 hash = keccak256(proof);
        require(!processedProofs[hash], "Already processed");

        processedProofs[hash] = true;
        IERC20 token = IERC20(assetToERC20[assetId]);
        token.transfer(sender, amt);

        emit Wrapped(sender, assetId, amt);
    }
}
