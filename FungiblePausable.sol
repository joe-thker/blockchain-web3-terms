// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FungiblePausable is ERC20Pausable, Ownable {
    constructor(address initialOwner)
        ERC20("Pausable Token", "PAUZ")
        Ownable(initialOwner)
    {
        _mint(initialOwner, 1_000_000 * 1e18);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // ✅ Correctly overriding from both ERC20 and Pausable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
