// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Flatcoin
 * @dev Inflation-resistant stablecoin pegged to a CPI index (mocked here).
 */
contract Flatcoin is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;
    uint256 public lastCPI;        // Simulated CPI value (e.g., 100.0 = 10000)
    uint256 public currentCPI;     // Updated CPI
    uint256 public lastMintTime;

    address public cpiOracle;

    event CPIUpdated(uint256 oldCPI, uint256 newCPI);
    event OracleChanged(address indexed oldOracle, address indexed newOracle);

    constructor() ERC20("Flatcoin", "FLAT") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
        lastCPI = 10000; // CPI base 100.00
        currentCPI = 10000;
        lastMintTime = block.timestamp;
    }

    modifier onlyOracle() {
        require(msg.sender == cpiOracle, "Not oracle");
        _;
    }

    function setOracle(address _oracle) external onlyOwner {
        emit OracleChanged(cpiOracle, _oracle);
        cpiOracle = _oracle;
    }

    /**
     * @notice Oracle calls this to update CPI (scaled x100).
     * Example: 105.2 CPI = 10520
     */
    function updateCPI(uint256 newCPI) external onlyOracle {
        require(newCPI > 0, "Invalid CPI");
        emit CPIUpdated(currentCPI, newCPI);
        lastCPI = currentCPI;
        currentCPI = newCPI;
    }

    /**
     * @notice Mint additional FLAT tokens based on inflation delta.
     * @dev Simulates adjusting supply to maintain flat purchasing power.
     */
    function mintWithInflation() external onlyOwner {
        require(block.timestamp > lastMintTime + 30 days, "Wait a month");
        require(currentCPI > lastCPI, "No inflation");

        uint256 inflationRate = ((currentCPI - lastCPI) * 1e18) / lastCPI;
        uint256 additionalMint = (totalSupply() * inflationRate) / 1e18;

        _mint(owner(), additionalMint);
        lastMintTime = block.timestamp;
    }

    /**
     * @notice Allows user to burn their tokens (deflationary optional feature).
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
