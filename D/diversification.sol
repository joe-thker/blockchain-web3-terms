// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Minimal interface for the stablecoin and for the basket tokens (ERC20).
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

/// @title Diversification
/// @notice A dynamic and optimized contract that allows users to deposit a stablecoin and invests it 
/// into a “diversified” basket of ERC20 tokens. The owner can update token allocations, and users
/// can withdraw their share. This is a simplified demonstration of diversification logic.
contract Diversification is Ownable, ReentrancyGuard {
    /// @notice The stablecoin (e.g. USDT, USDC) used for depositing.
    IERC20 public stableToken;

    /// @notice Each “basket token” that the stablecoin is allocated to, plus an allocation weight in basis points.
    struct BasketToken {
        address token;        // ERC20 token address
        uint256 allocationBps; // e.g. 3000 for 30%, 2000 for 20%, etc.
        bool active;          // whether this token is active in the basket
    }

    /// @notice Array storing basket tokens (the “diversified” set). 
    BasketToken[] public basket;
    // Mapping from token address => index+1 to quickly check if token is in the basket
    mapping(address => uint256) public basketIndexPlusOne;

    /// @notice Sum of all allocationBps for active tokens. Must be <= 10000 (100%)
    uint256 public totalAllocationBps;

    /// @notice Mapping from user => stableToken deposit balance. In a real system, you'd track shares of the basket.
    mapping(address => uint256) public userBalance;

    // --- Events ---
    event BasketTokenAdded(address indexed token, uint256 allocationBps);
    event BasketTokenUpdated(address indexed token, uint256 newAllocationBps);
    event BasketTokenRemoved(address indexed token);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 stableAmount, uint256[] tokenAmounts);

    /// @notice Constructor sets the stablecoin address and sets deployer as owner.
    /// @param _stableToken The ERC20 stablecoin used for deposit.
    constructor(address _stableToken) Ownable(msg.sender) {
        require(_stableToken != address(0), "Invalid stablecoin address");
        stableToken = IERC20(_stableToken);
    }

    // --- Owner Functions ---

    /// @notice Owner adds a token to the basket with a certain allocation in basis points.
    /// @param token The ERC20 token address.
    /// @param allocationBps The allocation in basis points (e.g., 3000 = 30%).
    function addBasketToken(address token, uint256 allocationBps) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(allocationBps > 0, "Allocation must be > 0");
        require(totalAllocationBps + allocationBps <= 10000, "Total allocation exceeds 100%");
        require(basketIndexPlusOne[token] == 0, "Token already in basket");

        basket.push(BasketToken({
            token: token,
            allocationBps: allocationBps,
            active: true
        }));
        basketIndexPlusOne[token] = basket.length;
        totalAllocationBps += allocationBps;

        emit BasketTokenAdded(token, allocationBps);
    }

    /// @notice Updates the allocation of an existing basket token.
    /// @param token The token address to update.
    /// @param newBps The new allocation in basis points.
    function updateBasketToken(address token, uint256 newBps) external onlyOwner {
        uint256 idxPlusOne = basketIndexPlusOne[token];
        require(idxPlusOne != 0, "Token not in basket");
        uint256 index = idxPlusOne - 1;

        BasketToken storage bt = basket[index];
        require(bt.active, "Token is inactive");
        require(newBps > 0, "Allocation must be > 0");

        // adjust totalAllocationBps
        // remove old, add new
        totalAllocationBps = totalAllocationBps - bt.allocationBps + newBps;
        require(totalAllocationBps <= 10000, "Total allocation exceeds 100%");

        bt.allocationBps = newBps;

        emit BasketTokenUpdated(token, newBps);
    }

    /// @notice Removes (deactivates) a token from the basket, so it cannot be allocated in future. 
    /// The totalAllocationBps is reduced accordingly.
    /// @param token The token address to remove.
    function removeBasketToken(address token) external onlyOwner {
        uint256 idxPlusOne = basketIndexPlusOne[token];
        require(idxPlusOne != 0, "Token not in basket");
        uint256 index = idxPlusOne - 1;
        BasketToken storage bt = basket[index];
        require(bt.active, "Token already inactive");

        bt.active = false;
        totalAllocationBps -= bt.allocationBps;
        bt.allocationBps = 0;

        basketIndexPlusOne[token] = 0;
        emit BasketTokenRemoved(token);
    }

    // --- User Deposit & Withdraw ---

    /// @notice User deposits stable tokens into the aggregator contract.
    /// In a real system, the contract might automatically invest them across the basket. 
    /// For demonstration, we keep a simple userBalance in stable tokens.
    /// @param amount The amount of stable tokens to deposit.
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit must be > 0");
        bool success = stableToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Stable transfer failed");
        
        userBalance[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    /// @notice User withdraws their entire balance. The contract “sells” their share of the basket
    /// if needed. For demonstration, we skip the actual rebalancing logic and assume we hold stable tokens only.
    /// A real aggregator might have to swap tokens back to stable, track share ratios, etc.
    function withdraw() external nonReentrant {
        uint256 balance = userBalance[msg.sender];
        require(balance > 0, "No funds to withdraw");

        // For demonstration, we pretend we've also invested in multiple tokens
        // and must “withdraw” them proportionally. We'll just do stable token 
        // plus dummy array of zero amounts for each basket token.
        uint256[] memory tokenWithdrawals = new uint256[](basket.length);

        // Reset user’s balance
        userBalance[msg.sender] = 0;

        // Transfer stable back
        bool success = stableToken.transfer(msg.sender, balance);
        require(success, "Stable transfer failed");

        // In a real aggregator, we'd iterate over each basket token, compute the user’s share, and transfer them out.
        // For demonstration, we do zero amounts. You can expand logic to track actual token holdings.

        emit Withdraw(msg.sender, balance, tokenWithdrawals);
    }

    // --- View Functions ---

    /// @notice Returns the number of tokens in the basket (including inactive ones).
    /// @return The length of the basket array.
    function totalBasketTokens() external view returns (uint256) {
        return basket.length;
    }

    /// @notice Retrieves the basket token info by index in the basket array.
    /// @param index The index of the basket token in the basket array.
    /// @return A BasketToken struct with token address, allocation, and active status.
    function getBasketToken(uint256 index)
        external
        view
        returns (BasketToken memory)
    {
        require(index < basket.length, "Index out of range");
        return basket[index];
    }
}
