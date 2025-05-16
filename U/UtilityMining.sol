// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title UtilityMiningNFT - Mint NFTs and get utility mining rewards
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract UtilityMiningNFT {
    address public owner;
    IERC20 public rewardToken;

    uint256 public rewardPerMint = 100 * 1e18;
    uint256 public totalMinted;
    mapping(address => uint256) public userMints;

    event NFTMinted(address indexed user, uint256 tokenId, uint256 rewardGiven);

    constructor(address _rewardToken) {
        owner = msg.sender;
        rewardToken = IERC20(_rewardToken);
    }

    function mint() external {
        totalMinted++;
        userMints[msg.sender]++;

        // Simulate NFT mint — not an actual ERC721 for simplicity
        uint256 tokenId = totalMinted;

        // Reward user with utility mining token
        rewardToken.transfer(msg.sender, rewardPerMint);

        emit NFTMinted(msg.sender, tokenId, rewardPerMint);
    }

    function updateReward(uint256 newReward) external {
        require(msg.sender == owner, "Only owner");
        rewardPerMint = newReward;
    }
}
