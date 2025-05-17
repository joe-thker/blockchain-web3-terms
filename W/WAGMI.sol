// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title WAGMINFT - Symbolic badge for verified contributors
contract WAGMINFT is ERC721Enumerable, Ownable {
    mapping(address => bool) public hasMinted;
    uint256 public tokenCounter;
    uint256 public immutable mintDeadline;

    event WAGMIMinted(address indexed user, uint256 tokenId);

    constructor(uint256 _mintPeriod) ERC721("WAGMI Badge", "WAGMI") {
        mintDeadline = block.timestamp + _mintPeriod;
    }

    function mintWAGMI() external {
        require(block.timestamp <= mintDeadline, "Mint closed");
        require(!hasMinted[msg.sender], "Already minted");

        uint256 tokenId = ++tokenCounter;
        _safeMint(msg.sender, tokenId);
        hasMinted[msg.sender] = true;

        emit WAGMIMinted(msg.sender, tokenId);
    }

    function isWAGMI(address user) external view returns (bool) {
        return hasMinted[user];
    }
}

/// @title WAGMIGate - Grants access only to WAGMI holders
contract WAGMIGate {
    address public immutable wagmiNFT;

    constructor(address _wagmiNFT) {
        wagmiNFT = _wagmiNFT;
    }

    modifier onlyWAGMI() {
        require(WAGMINFT(wagmiNFT).balanceOf(msg.sender) > 0, "Not WAGMI");
        _;
    }

    function enterWAGMIClub() external view onlyWAGMI returns (string memory) {
        return "🎉 Welcome, fellow WAGMI. We believe in the mission!";
    }
}
