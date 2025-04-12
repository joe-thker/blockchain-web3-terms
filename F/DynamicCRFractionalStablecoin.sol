// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IPriceOracle {
    function getPrice() external view returns (uint256); // scaled to 1e8
}

interface IGovToken {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract DynamicCRFractionalStablecoin is ERC20, Ownable {
    uint256 public collateralRatio = 7500; // scaled to 10000 = 100%
    uint256 public constant RATIO_SCALE = 1e4;
    uint256 public constant PRICE_TARGET = 1e8; // $1.00 in 1e8

    address public govToken;
    IPriceOracle public priceOracle;

    constructor(address _govToken, address _oracle)
        ERC20("DynamicFUSD", "dFUSD")
        Ownable(msg.sender)
    {
        govToken = _govToken;
        priceOracle = IPriceOracle(_oracle);
    }

    function updateCR() public {
        uint256 price = priceOracle.getPrice();
        if (price > PRICE_TARGET) {
            // FUSD > $1 → reduce CR
            if (collateralRatio > 5000) {
                collateralRatio -= 100;
            }
        } else if (price < PRICE_TARGET) {
            // FUSD < $1 → increase CR
            if (collateralRatio < 9500) {
                collateralRatio += 100;
            }
        }
    }

    function mint() external payable {
        require(msg.value > 0, "Send ETH");
        updateCR();

        uint256 totalValue = msg.value * PRICE_TARGET / 1e18; // ETH to USD
        uint256 ethValue = (totalValue * collateralRatio) / RATIO_SCALE;
        uint256 fraValue = totalValue - ethValue;
        uint256 fraAmount = (fraValue * 1e18) / PRICE_TARGET;

        require(
            IGovToken(govToken).transferFrom(msg.sender, address(this), fraAmount),
            "FRA transfer failed"
        );

        _mint(msg.sender, totalValue);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        updateCR();

        uint256 ethValue = (amount * collateralRatio) / RATIO_SCALE;
        uint256 fraValue = amount - ethValue;

        uint256 ethToSend = (ethValue * 1e18) / PRICE_TARGET;
        uint256 fraToSend = (fraValue * 1e18) / PRICE_TARGET;

        require(address(this).balance >= ethToSend, "Not enough ETH");
        require(IGovToken(govToken).transfer(msg.sender, fraToSend), "FRA transfer failed");

        payable(msg.sender).transfer(ethToSend);
    }

    receive() external payable {}
}
