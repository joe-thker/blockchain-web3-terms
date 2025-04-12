// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IVolatileToken {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract DualTokenFractionalStablecoin is ERC20, Ownable {
    address public volatileToken;
    uint256 public collateralRatio = 8000; // 80%
    uint256 public constant RATIO_SCALE = 1e4;
    uint256 public constant USD = 1e18;

    constructor(address _volatileToken)
        ERC20("DualFUSD", "fFRAX")
        Ownable(msg.sender)
    {
        volatileToken = _volatileToken;
    }

    function mint() external payable {
        uint256 totalValue = msg.value * USD / 1e18;
        uint256 ethPortion = (totalValue * collateralRatio) / RATIO_SCALE;
        uint256 volPortion = totalValue - ethPortion;

        uint256 volAmount = (volPortion * 1e18) / USD;

        require(
            IVolatileToken(volatileToken).transferFrom(msg.sender, address(this), volAmount),
            "FXS transfer failed"
        );

        _mint(msg.sender, totalValue);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);

        uint256 ethShare = (amount * collateralRatio) / RATIO_SCALE;
        uint256 volShare = amount - ethShare;

        uint256 ethToSend = (ethShare * 1e18) / USD;
        uint256 volToSend = (volShare * 1e18) / USD;

        require(address(this).balance >= ethToSend, "Insufficient ETH");
        require(IVolatileToken(volatileToken).transfer(msg.sender, volToSend), "FXS refund failed");

        payable(msg.sender).transfer(ethToSend);
    }

    receive() external payable {}
}
