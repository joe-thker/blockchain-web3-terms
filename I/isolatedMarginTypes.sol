// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Isolated Margin Types
/// @notice Simulates different isolated margin modes in Solidity

/// 1. ETH-Based Isolated Margin
contract ETHIsolatedMargin {
    struct Position {
        uint256 margin;
        uint256 leverage;
        uint256 entryPrice;
        bool open;
    }

    mapping(address => Position) public positions;

    function openPosition(uint256 entryPrice, uint256 leverage) external payable {
        require(!positions[msg.sender].open, "Position already open");
        require(msg.value > 0, "No margin");

        positions[msg.sender] = Position({
            margin: msg.value,
            leverage: leverage,
            entryPrice: entryPrice,
            open: true
        });
    }

    function closePosition() external {
        require(positions[msg.sender].open, "No open position");
        delete positions[msg.sender];
    }
}

/// 2. ERC20-Based Isolated Margin
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenIsolatedMargin {
    IERC20 public token;

    struct Position {
        uint256 margin;
        uint256 leverage;
        uint256 entryPrice;
        bool open;
    }

    mapping(address => Position) public positions;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function openPosition(uint256 amount, uint256 leverage, uint256 entryPrice) external {
        require(!positions[msg.sender].open, "Position already open");
        require(amount > 0, "No margin");

        token.transferFrom(msg.sender, address(this), amount);

        positions[msg.sender] = Position({
            margin: amount,
            leverage: leverage,
            entryPrice: entryPrice,
            open: true
        });
    }

    function closePosition() external {
        require(positions[msg.sender].open, "No open position");
        delete positions[msg.sender];
    }
}

/// 3. NFT-Based Isolated Margin (Staking NFTs for Margin)
interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract NFTMarginVault {
    IERC721 public nft;

    struct Position {
        uint256 tokenId;
        uint256 leverage;
        bool open;
    }

    mapping(address => Position) public nftPositions;

    constructor(address _nft) {
        nft = IERC721(_nft);
    }

    function openPosition(uint256 tokenId, uint256 leverage) external {
        require(!nftPositions[msg.sender].open, "Position already open");
        nft.transferFrom(msg.sender, address(this), tokenId);
        nftPositions[msg.sender] = Position({
            tokenId: tokenId,
            leverage: leverage,
            open: true
        });
    }

    function closePosition() external {
        Position memory pos = nftPositions[msg.sender];
        require(pos.open, "No open position");
        delete nftPositions[msg.sender];
        nft.transferFrom(address(this), msg.sender, pos.tokenId);
    }
}

/// 4. Oracle-Pegged Isolated Margin
contract OracleIsolatedMargin {
    mapping(address => uint256) public margins;
    mapping(address => uint256) public entryPrices;

    function openPosition(uint256 entryPrice) external payable {
        require(msg.value > 0, "No margin");
        margins[msg.sender] = msg.value;
        entryPrices[msg.sender] = entryPrice;
    }

    function getLiquidationPrice(uint256 leverage) external view returns (uint256) {
        uint256 entry = entryPrices[msg.sender];
        return entry - (entry * leverage) / 100; // e.g., 5x => 80% drop
    }
}
