// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITokenOracle {
    function getTokenPrice() external view returns (uint256);
}

contract FDVGoverned {
    address public governor;
    uint256 public maxSupply;
    ITokenOracle public oracle;

    event SupplyCapUpdated(uint256 newCap);

    constructor(address _oracle, uint256 initialCap) {
        governor = msg.sender;
        oracle = ITokenOracle(_oracle);
        maxSupply = initialCap;
    }

    modifier onlyGovernor() {
        require(msg.sender == governor, "Not governor");
        _;
    }

    function updateMaxSupply(uint256 newCap) external onlyGovernor {
        require(newCap >= maxSupply, "Cannot reduce supply cap");
        maxSupply = newCap;
        emit SupplyCapUpdated(newCap);
    }

    function getFDV() public view returns (uint256) {
        return (oracle.getTokenPrice() * maxSupply) / 1e18;
    }
}
