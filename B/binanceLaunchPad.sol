// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

/// @title BinanceLaunchpadSale
/// @notice A simplified token sale contract simulating a Binance Launchpad event for a BEP-20 token.
contract BinanceLaunchpadSale {
    address public owner;
    IBEP20 public saleToken;        // Token being sold
    uint256 public tokenPrice;      // Price in wei per token
    uint256 public saleStart;       // Sale start time (Unix timestamp)
    uint256 public saleEnd;         // Sale end time (Unix timestamp)
    uint256 public tokensForSale;   // Total tokens allocated for the sale
    uint256 public tokensSold;      // Total tokens sold

    bool public saleFinalized;      // Indicates if the sale has been finalized

    // Mapping from buyer address to purchased token amount (pending claim)
    mapping(address => uint256) public purchasedTokens;

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event SaleFinalized(uint256 tokensSold, uint256 unsoldTokens);
    event TokensClaimed(address indexed buyer, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier saleActive() {
        require(block.timestamp >= saleStart && block.timestamp <= saleEnd, "Sale is not active");
        _;
    }

    constructor(
        address _saleToken, 
        uint256 _tokenPrice, 
        uint256 _saleStart, 
        uint256 _saleEnd, 
        uint256 _tokensForSale
    ) {
        require(_saleStart < _saleEnd, "Sale start must be before sale end");
        owner = msg.sender;
        saleToken = IBEP20(_saleToken);
        tokenPrice = _tokenPrice;
        saleStart = _saleStart;
        saleEnd = _saleEnd;
        tokensForSale = _tokensForSale;
    }

    /// @notice Allows users to purchase tokens during the sale.
    /// @param tokenAmount The number of tokens the buyer wants to purchase.
    function buyTokens(uint256 tokenAmount) external payable saleActive {
        uint256 cost = tokenAmount * tokenPrice;
        require(msg.value >= cost, "Insufficient BNB sent");
        require(tokensSold + tokenAmount <= tokensForSale, "Not enough tokens available");

        tokensSold += tokenAmount;
        purchasedTokens[msg.sender] += tokenAmount;

        // Refund any excess BNB sent
        if(msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit TokensPurchased(msg.sender, tokenAmount, cost);
    }

    /// @notice Finalizes the sale after the sale period ends.
    /// Transfers collected BNB to the owner and returns unsold tokens to the owner.
    function finalizeSale() external onlyOwner {
        require(block.timestamp > saleEnd, "Sale has not ended");
        require(!saleFinalized, "Sale already finalized");
        saleFinalized = true;

        // Transfer BNB collected to owner.
        payable(owner).transfer(address(this).balance);

        // Optionally, return unsold tokens to the owner.
        uint256 unsold = tokensForSale - tokensSold;
        if(unsold > 0) {
            require(saleToken.transfer(owner, unsold), "Transfer of unsold tokens failed");
        }
        emit SaleFinalized(tokensSold, unsold);
    }

    /// @notice Allows buyers to claim their purchased tokens after the sale is finalized.
    function claimTokens() external {
        require(saleFinalized, "Sale not finalized");
        uint256 amount = purchasedTokens[msg.sender];
        require(amount > 0, "No tokens to claim");
        purchasedTokens[msg.sender] = 0;
        require(saleToken.transfer(msg.sender, amount), "Token transfer failed");
        emit TokensClaimed(msg.sender, amount);
    }
}
