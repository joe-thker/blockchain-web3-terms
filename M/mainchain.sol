// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Main Chain Checker
contract MainChainGuard {
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;

    function isMainChain() public view returns (bool) {
        return block.chainid == ETH_MAINNET_CHAIN_ID;
    }

    function onlyMainChainLogic() external view returns (string memory) {
        require(isMainChain(), "Not on main chain");
        return "Executing only on Ethereum Mainnet!";
    }
}
