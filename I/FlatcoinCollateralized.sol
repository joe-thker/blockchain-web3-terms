// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FlatcoinCollateralized
 * @dev Mintable stablecoin backed by ETH collateral with minimum 150% ratio.
 */
contract FlatcoinCollateralized is ERC20, Ownable {
    mapping(address => uint256) public collateral;
    uint256 public collateralRatio = 150; // 150% collateral required

    constructor() ERC20("FlatcoinCollateral", "FLATCOL") Ownable(msg.sender) {}

    /**
     * @notice Deposit ETH as collateral
     */
    function depositCollateral() external payable {
        require(msg.value > 0, "Zero value");
        collateral[msg.sender] += msg.value;
    }

    /**
     * @notice Mint flatcoins if collateral ratio is met
     * @param amount Amount of FLATCOL tokens to mint
     */
    function mint(uint256 amount) external {
        uint256 requiredCollateral = (amount * collateralRatio) / 100;
        require(collateral[msg.sender] >= requiredCollateral, "Not enough ETH");
        _mint(msg.sender, amount);
    }

    /**
     * @notice Burn flatcoins and withdraw ETH
     * @param amount Amount of FLATCOL to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        uint256 returnCollateral = (amount * collateralRatio) / 100;
        require(collateral[msg.sender] >= returnCollateral, "Insufficient collateral");
        collateral[msg.sender] -= returnCollateral;
        payable(msg.sender).transfer(returnCollateral);
    }

    receive() external payable {}
}
