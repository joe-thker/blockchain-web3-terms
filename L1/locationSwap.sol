// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function burn(uint256 amount) external;
    function mint(address to, uint256 amount) external;
}

/// @title LocationSwapVault – Burn-on-source, mint-on-target cross-chain token relocation
contract LocationSwapVault {
    IERC20 public token; // e.g., wstETH or another wrapped token

    address public relayer; // Trusted off-chain relayer or bridge listener
    mapping(bytes32 => bool) public approvedChains;

    event SwapInitiated(address indexed user, uint256 amount, string destination);

    constructor(address _token, address _relayer) {
        token = IERC20(_token);
        relayer = _relayer;
    }

    /// @notice Only relayer can manage approved chains
    function setApprovedDestination(string memory chainName, bool approved) external {
        require(msg.sender == relayer, "Only relayer can set destinations");
        approvedChains[keccak256(bytes(chainName))] = approved;
    }

    /// @notice Burn tokens to swap their *location* to another chain
    function initiateLocationSwap(uint256 amount, string calldata destinationChain) external {
        bytes32 destKey = keccak256(bytes(destinationChain));
        require(approvedChains[destKey], "Destination not approved");

        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        token.burn(amount); // Burn tokens on source chain

        emit SwapInitiated(msg.sender, amount, destinationChain);
        // Off-chain listener will mint on destination
    }
}
