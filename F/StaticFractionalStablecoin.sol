// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGovToken {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract StaticFractionalStablecoin is ERC20, Ownable {
    address public govToken;
    uint256 public constant PRICE = 1e18;
    uint256 public constant RATIO_SCALE = 1e4;
    uint256 public collateralRatio = 7500; // 75%

    constructor(address _govToken) ERC20("StaticFUSD", "sFUSD") Ownable(msg.sender) {
        govToken = _govToken;
    }

    function mint() external payable {
        require(msg.value > 0, "Send ETH");

        uint256 value = msg.value * PRICE / 1e18;
        uint256 ethValue = (value * collateralRatio) / RATIO_SCALE;
        uint256 fraValue = value - ethValue;
        uint256 fraAmount = (fraValue * 1e18) / PRICE;

        require(
            IGovToken(govToken).transferFrom(msg.sender, address(this), fraAmount),
            "FRA transfer failed"
        );

        _mint(msg.sender, value);
    }

    function burn(uint256 fusdAmount) external {
        _burn(msg.sender, fusdAmount);

        uint256 ethPortion = (fusdAmount * collateralRatio) / RATIO_SCALE;
        uint256 fraPortion = fusdAmount - ethPortion;

        uint256 ethToSend = (ethPortion * 1e18) / PRICE;
        uint256 fraToSend = (fraPortion * 1e18) / PRICE;

        require(address(this).balance >= ethToSend, "Not enough ETH");
        require(IGovToken(govToken).transfer(msg.sender, fraToSend), "FRA transfer failed");

        payable(msg.sender).transfer(ethToSend);
    }

    receive() external payable {}
}
