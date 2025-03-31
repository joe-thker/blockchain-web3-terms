// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice A minimal interface for a Curve-like pool.
/// In a real-world scenario, the pool would have additional functions and complexity.
interface ICurvePool {
    /// @notice Adds liquidity to the pool.
    /// @param amounts An array with amounts for each token (here, we assume a 2-token pool).
    /// @param min_mint_amount The minimum amount of liquidity tokens to mint.
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external;

    /// @notice Removes liquidity from the pool.
    /// @param _amount The amount of liquidity tokens to remove.
    /// @param min_amounts The minimum amounts of each token to receive.
    function remove_liquidity(uint256 _amount, uint256[2] calldata min_amounts) external;
}

/// @title CurveAMO
/// @notice A simplified example of a Curve Automated Market Operations (AMO) contract.
/// It accepts deposits of a stablecoin, invests the funds into a Curve-like pool,
/// and allows the owner to withdraw liquidity. Key parameters (such as the pool address
/// and minimum mint amount) can be updated dynamically.
contract CurveAMO is Ownable, ReentrancyGuard {
    // The stablecoin to be managed by the AMO.
    IERC20 public stablecoin;
    // The Curve-like pool where funds will be invested.
    ICurvePool public curvePool;
    // Minimum liquidity tokens that must be minted during an add_liquidity operation.
    uint256 public minMintAmount;

    // --- Events ---
    event PoolUpdated(address indexed newPool);
    event MinMintAmountUpdated(uint256 newMinMintAmount);
    event StablecoinDeposited(address indexed sender, uint256 amount);
    event Invested(uint256 stablecoinAmount);
    event LiquidityWithdrawn(uint256 liquidityRemoved);

    /// @notice Constructor sets the stablecoin, the initial pool, and the minimum mint amount.
    /// @param _stablecoin The address of the ERC20 stablecoin.
    /// @param _curvePool The address of the Curve-like pool.
    /// @param _minMintAmount The initial minimum liquidity mint amount.
    constructor(IERC20 _stablecoin, ICurvePool _curvePool, uint256 _minMintAmount) Ownable(msg.sender) {
        require(address(_stablecoin) != address(0), "Invalid stablecoin address");
        require(address(_curvePool) != address(0), "Invalid pool address");
        stablecoin = _stablecoin;
        curvePool = _curvePool;
        minMintAmount = _minMintAmount;
    }

    /// @notice Updates the pool address.
    /// @param _newPool The new Curve pool address.
    function updatePool(ICurvePool _newPool) external onlyOwner {
        require(address(_newPool) != address(0), "Invalid pool address");
        curvePool = _newPool;
        emit PoolUpdated(address(_newPool));
    }

    /// @notice Updates the minimum mint amount required when adding liquidity.
    /// @param _minMintAmount The new minimum mint amount.
    function updateMinMintAmount(uint256 _minMintAmount) external onlyOwner {
        minMintAmount = _minMintAmount;
        emit MinMintAmountUpdated(_minMintAmount);
    }

    /// @notice Deposits stablecoin into the contract.
    /// The owner must approve the transfer before calling this function.
    /// @param amount The amount of stablecoin to deposit.
    function depositStablecoin(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(stablecoin.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit StablecoinDeposited(msg.sender, amount);
    }

    /// @notice Invests all stablecoin held by the contract into the Curve pool.
    /// This function approves the pool to spend the stablecoin and calls add_liquidity.
    function invest() external onlyOwner nonReentrant {
        uint256 balance = stablecoin.balanceOf(address(this));
        require(balance > 0, "No stablecoin to invest");
        // Approve the pool to spend the stablecoin.
        stablecoin.approve(address(curvePool), balance);
        // Create an array for liquidity deposit.
        uint256[2] memory amounts;
        amounts[0] = balance; // Deposit the entire stablecoin balance.
        amounts[1] = 0;       // Assume the second token is not used.
        curvePool.add_liquidity(amounts, minMintAmount);
        emit Invested(balance);
    }

    /// @notice Withdraws liquidity from the Curve pool.
    /// @param liquidityAmount The amount of liquidity tokens to withdraw.
    /// @param minAmounts The minimum amounts of each token to receive upon withdrawal.
    function withdrawInvested(uint256 liquidityAmount, uint256[2] calldata minAmounts) external onlyOwner nonReentrant {
        curvePool.remove_liquidity(liquidityAmount, minAmounts);
        emit LiquidityWithdrawn(liquidityAmount);
    }
}
