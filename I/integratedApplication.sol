// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title IntegratedApplicationCore
/// @notice Example of an integrated smart contract interacting with ETH, ERC20, and external data.
contract IntegratedApplicationCore is Ownable {
    IERC20 public paymentToken;
    uint256 public appFee;
    mapping(address => string[]) public userMetadata;

    event PaymentReceived(address indexed user, uint256 amount, string serviceID);
    event DataStored(address indexed user, string metadataHash);

    constructor(IERC20 _token, uint256 _appFee) Ownable(msg.sender) {
        paymentToken = _token;
        appFee = _appFee; // Fee in token decimals
    }

    /// @notice Accept ETH for a service and log the purchase
    function payWithETH(string calldata serviceID) external payable {
        require(msg.value >= 1 ether, "Min 1 ETH");
        emit PaymentReceived(msg.sender, msg.value, serviceID);
    }

    /// @notice Pay using ERC20 token
    function payWithToken(string calldata serviceID) external {
        paymentToken.transferFrom(msg.sender, address(this), appFee);
        emit PaymentReceived(msg.sender, appFee, serviceID);
    }

    /// @notice Store metadata that references off-chain content (e.g., IPFS, Arweave, JSON-API)
    function storeMetadata(string calldata hashRef) external {
        userMetadata[msg.sender].push(hashRef);
        emit DataStored(msg.sender, hashRef);
    }

    /// @notice Admin can withdraw funds
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
        uint256 tokenBal = paymentToken.balanceOf(address(this));
        paymentToken.transfer(owner(), tokenBal);
    }
}
