// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TotalExchangeVolumeModule - Tracks Exchange Volume with Security Considerations

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

/// 🔁 Volume DEX (Simplified Swap Engine)
contract VolumeDEX {
    address public tokenA;
    address public tokenB;
    uint256 public totalVolume;
    mapping(address => uint256) public userVolume;
    mapping(bytes32 => uint256) public pairVolume;

    event Swapped(address indexed user, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function swapAtoB(uint256 amountIn) external {
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountIn), "Transfer A failed");

        uint256 amountOut = getQuoteAtoB(amountIn);
        IERC20(tokenB).transfer(msg.sender, amountOut);

        _logVolume(msg.sender, tokenA, tokenB, amountIn);
        emit Swapped(msg.sender, amountIn, amountOut);
    }

    function getQuoteAtoB(uint256 amountIn) public pure returns (uint256) {
        return amountIn * 99 / 100; // 1% fee
    }

    function _logVolume(address user, address from, address to, uint256 amountIn) internal {
        totalVolume += amountIn;
        userVolume[user] += amountIn;

        bytes32 pairKey = keccak256(abi.encodePacked(from, to));
        pairVolume[pairKey] += amountIn;
    }

    function getPairVolume(address from, address to) external view returns (uint256) {
        return pairVolume[keccak256(abi.encodePacked(from, to))];
    }

    function getUserVolume(address user) external view returns (uint256) {
        return userVolume[user];
    }
}

/// 🔓 Volume Attacker (Wash Trade / Volume Pump)
interface IVolumeDEX {
    function swapAtoB(uint256) external;
}

contract VolumeAttacker {
    function washTrade(IVolumeDEX dex, uint256 times, uint256 amount) external {
        for (uint256 i = 0; i < times; i++) {
            dex.swapAtoB(amount);
        }
    }
}
