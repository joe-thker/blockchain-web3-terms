// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OpenSeaClone
 * @notice A simple NFT marketplace inspired by OpenSea:
 *         • Sellers list ERC‑721 tokens at a fixed price.
 *         • Buyers purchase by sending exact ETH.
 *         • Marketplace takes a configurable fee (in basis points).
 *
 * FIX: Added `constructor(_feeRecipient) Ownable(msg.sender)` so the
 *      OpenZeppelin Ownable base constructor receives its required
 *      initialOwner argument, eliminating the compilation error.
 */
contract OpenSeaClone is ReentrancyGuard, Ownable {
    struct Listing {
        address seller;
        uint256 price;      // in wei
    }

    // token contract → token ID → Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    /// fee in basis points (100 bp = 1%), e.g. 250 = 2.5%
    uint16 public feeBps = 250;
    address public feeRecipient;

    event ItemListed(
        address indexed seller,
        address indexed token,
        uint256 indexed tokenId,
        uint256 price
    );
    event ListingCanceled(
        address indexed seller,
        address indexed token,
        uint256 indexed tokenId
    );
    event ItemSold(
        address indexed buyer,
        address indexed token,
        uint256 indexed tokenId,
        uint256 price
    );
    event FeeUpdated(uint16 newFeeBps, address newRecipient);

    /// @param _feeRecipient Address to receive marketplace fees
    constructor(address _feeRecipient) Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }

    /**
     * @notice List an ERC‑721 token for sale.
     */
    function listItem(
        address token,
        uint256 tokenId,
        uint256 price
    ) external nonReentrant {
        require(price > 0, "Price must be > 0");
        IERC721 nft = IERC721(token);
        require(nft.ownerOf(tokenId) == msg.sender, "Not token owner");
        require(
            nft.getApproved(tokenId) == address(this) ||
            nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        listings[token][tokenId] = Listing({
            seller: msg.sender,
            price: price
        });

        emit ItemListed(msg.sender, token, tokenId, price);
    }

    /**
     * @notice Cancel an existing listing.
     */
    function cancelListing(address token, uint256 tokenId) external nonReentrant {
        Listing memory lst = listings[token][tokenId];
        require(lst.seller == msg.sender, "Not seller");
        delete listings[token][tokenId];
        emit ListingCanceled(msg.sender, token, tokenId);
    }

    /**
     * @notice Buy a listed token by paying exactly the listing price.
     */
    function buyItem(address token, uint256 tokenId) external payable nonReentrant {
        Listing memory lst = listings[token][tokenId];
        require(lst.price > 0, "Not listed");
        require(msg.value == lst.price, "Incorrect ETH amount");

        // remove listing first to prevent reentrancy
        delete listings[token][tokenId];

        // calculate marketplace fee
        uint256 fee = (msg.value * feeBps) / 10_000;
        uint256 sellerProceeds = msg.value - fee;

        // transfer ETH to seller
        (bool sentSeller, ) = payable(lst.seller).call{value: sellerProceeds}("");
        require(sentSeller, "Seller payment failed");

        // transfer fee
        if (fee > 0) {
            (bool sentFee, ) = payable(feeRecipient).call{value: fee}("");
            require(sentFee, "Fee transfer failed");
        }

        // transfer NFT
        IERC721(token).safeTransferFrom(lst.seller, msg.sender, tokenId);

        emit ItemSold(msg.sender, token, tokenId, lst.price);
    }

    /**
     * @notice Update marketplace fee parameters.
     */
    function updateFee(uint16 _feeBps, address _recipient) external onlyOwner {
        require(_feeBps <= 1000, "Fee too high");
        require(_recipient != address(0), "Invalid recipient");
        feeBps = _feeBps;
        feeRecipient = _recipient;
        emit FeeUpdated(_feeBps, _recipient);
    }

    /**
     * @notice Retrieve a listing.
     */
    function getListing(address token, uint256 tokenId)
        external
        view
        returns (address seller, uint256 price)
    {
        Listing memory lst = listings[token][tokenId];
        return (lst.seller, lst.price);
    }
}
