// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function burn(uint256 amount) external;
}

contract MainnetSwapBridge {
    IERC20 public legacyToken;
    address public admin;

    event SwapInitiated(address indexed user, uint256 amount, string destinationAddress);

    constructor(address _legacyToken) {
        legacyToken = IERC20(_legacyToken);
        admin = msg.sender;
    }

    function swap(uint256 amount, string calldata destinationAddress) external {
        require(bytes(destinationAddress).length > 0, "Destination required");

        require(legacyToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        legacyToken.burn(amount); // Burn legacy ERC-20 token

        emit SwapInitiated(msg.sender, amount, destinationAddress);
        // Off-chain relayer watches this event and credits user on new mainnet
    }

    function withdrawUnclaimed(address to, uint256 amount) external {
        require(msg.sender == admin, "Not admin");
        legacyToken.transferFrom(address(this), to, amount);
    }
}
