// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGovToken {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract FractionalStablecoin is ERC20, Ownable {
    address public governanceToken;     // FRA token
    uint256 public collateralRatio = 7500; // 75% collateralized (scaled to 10000 = 100%)
    uint256 public constant PRICE = 1e18; // $1 target
    uint256 public constant RATIO_SCALE = 1e4;

    constructor(address _govToken) ERC20("Fractional USD", "FUSD") Ownable(msg.sender) {
        governanceToken = _govToken;
    }

    /// @notice Mint FUSD using ETH + FRA
    function mint() external payable {
        require(msg.value > 0, "Send ETH");

        uint256 totalValue = msg.value * PRICE / 1e18;
        uint256 fusdToMint = totalValue;

        uint256 ethValue = (fusdToMint * collateralRatio) / RATIO_SCALE;
        uint256 fraValue = fusdToMint - ethValue;

        uint256 fraAmount = (fraValue * 1e18) / PRICE;

        // Transfer required FRA from user to contract
        require(
            IGovToken(governanceToken).transferFrom(msg.sender, address(this), fraAmount),
            "FRA transfer failed"
        );

        _mint(msg.sender, fusdToMint);
    }

    /// @notice Burn FUSD and redeem ETH + FRA
    function burn(uint256 fusdAmount) external {
        require(balanceOf(msg.sender) >= fusdAmount, "Not enough FUSD");

        _burn(msg.sender, fusdAmount);

        uint256 ethPortion = (fusdAmount * collateralRatio) / RATIO_SCALE;
        uint256 fraPortion = fusdAmount - ethPortion;

        uint256 ethToSend = (ethPortion * 1e18) / PRICE;
        uint256 fraToSend = (fraPortion * 1e18) / PRICE;

        require(address(this).balance >= ethToSend, "Not enough ETH");
        require(IGovToken(governanceToken).transfer(msg.sender, fraToSend), "FRA transfer failed");

        payable(msg.sender).transfer(ethToSend);
    }

    /// @notice Admin can adjust collateral ratio
    function setCollateralRatio(uint256 newRatio) external onlyOwner {
        require(newRatio <= 10000, "Too high");
        collateralRatio = newRatio;
    }

    receive() external payable {}
}
