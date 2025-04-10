// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract VaultLPToken is ERC4626 {
    constructor(IERC20 _asset)
        ERC20("Vault LP", "VLP")
        ERC4626(_asset)
    {}
}
