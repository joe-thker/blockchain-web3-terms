// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * Signature‑Based NFT Marketplace
 * – Sellers sign a fixed‑price “order” off‑chain.
 * – Buyers submit order + signature + ETH; contract verifies and fills.
 * – Prevents front‑running and supports off‑chain orderbooks.
 */
contract SignatureMarketplace is ReentrancyGuard, Ownable, EIP712 {
    using ECDSA for bytes32;

    struct Order {
        address seller;
        address token;
        uint256 tokenId;
        uint256 price;
        uint256 nonce;
        uint256 deadline;
    }

    // orderHash => filled?
    mapping(bytes32 => bool) public filled;
    mapping(address => uint256) public nonces;

    uint16 public feeBps = 250;      // 2.5%
    address public feeRecipient;

    event OrderFilled(
        address indexed buyer,
        address indexed seller,
        address indexed token,
        uint256 tokenId,
        uint256 price
    );
    event FeeUpdated(uint16 newFeeBps, address newRecipient);

    constructor(address _feeRecipient)
        Ownable(msg.sender)
        EIP712("SignatureMarketplace", "1")
    {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }

    /**
     * @notice Fill an off‑chain signed order.
     */
    function fillOrder(
        Order calldata order,
        bytes calldata signature
    ) external payable nonReentrant {
        require(block.timestamp <= order.deadline, "Order expired");

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Order(address seller,address token,uint256 tokenId,uint256 price,uint256 nonce,uint256 deadline)"
                ),
                order.seller,
                order.token,
                order.tokenId,
                order.price,
                order.nonce,
                order.deadline
            )
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        require(!filled[hash], "Order already filled");

        address signer = hash.recover(signature);
        require(signer == order.seller, "Invalid signature");
        require(msg.value == order.price, "Incorrect ETH");

        filled[hash] = true;
        nonces[order.seller] = order.nonce + 1;

        // transfer NFT
        IERC721(order.token).safeTransferFrom(
            order.seller,
            msg.sender,
            order.tokenId
        );

        // distribute payment
        uint256 fee  = (msg.value * feeBps) / 10_000;
        uint256 vend = msg.value - fee;

        (bool sentSeller, ) = payable(order.seller).call{value: vend}("");
        require(sentSeller, "Payment to seller failed");

        if (fee > 0) {
            (bool sentFee, ) = payable(feeRecipient).call{value: fee}("");
            require(sentFee, "Payment of fee failed");
        }

        emit OrderFilled(
            msg.sender,
            order.seller,
            order.token,
            order.tokenId,
            order.price
        );
    }

    /**
     * @notice Update marketplace fee parameters.
     */
    function updateFee(uint16 _feeBps, address _recipient) external onlyOwner {
        require(_feeBps <= 1000, "Fee<=10%");   // ASCII "<=" only
        require(_recipient != address(0), "Invalid fee recipient");
        feeBps       = _feeBps;
        feeRecipient = _recipient;
        emit FeeUpdated(_feeBps, _recipient);
    }
}
