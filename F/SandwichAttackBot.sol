// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// ✅ Full IERC20 interface with balanceOf and approve
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256); // ✅ Add this
}

interface IDex {
    function buyToken() external payable;
    function sellToken(uint256 amount) external;
}

contract SandwichAttackBot {
    IDex public dex;
    IERC20 public token;
    address public owner;

    constructor(address _dex, address _token) {
        dex = IDex(_dex);
        token = IERC20(_token);
        owner = msg.sender;
    }

    function sandwichAttack() external payable {
        require(msg.sender == owner, "Not owner");

        // Step 1: Buy tokens before victim
        dex.buyToken{value: msg.value}();

        // Step 2: Sell tokens after victim (simulate sandwich)
        uint256 tokenBalance = token.balanceOf(address(this)); // ✅ Now valid
        token.approve(address(dex), tokenBalance);
        dex.sellToken(tokenBalance);
    }
}
