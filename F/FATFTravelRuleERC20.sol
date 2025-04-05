// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FATFTravelRuleERC20
 * @dev ERC20 token that enforces FATF Travel Rule by requiring travel rule data on every transfer.
 * Standard transfer and transferFrom are disabled.
 */
contract FATFTravelRuleERC20 is ERC20, Ownable {
    // Emitted when a travel rule compliant transfer occurs.
    event TravelRuleTransfer(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        string originatorInfo,
        string beneficiaryInfo
    );

    /**
     * @dev Constructor mints the initial supply to the deployer.
     * @param initialSupply Total token supply in smallest units (e.g. wei).
     */
    constructor(uint256 initialSupply)
        ERC20("FATF Travel Rule ERC20", "FTR20")
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Transfers tokens along with the required FATF Travel Rule data.
     * @param recipient Address receiving the tokens.
     * @param amount Amount to transfer.
     * @param originatorInfo Additional required info for the sender (e.g. KYC ID).
     * @param beneficiaryInfo Additional required info for the recipient.
     */
    function transferWithTravelRule(
        address recipient,
        uint256 amount,
        string calldata originatorInfo,
        string calldata beneficiaryInfo
    ) external returns (bool) {
        require(bytes(originatorInfo).length > 0, "Originator info required");
        require(bytes(beneficiaryInfo).length > 0, "Beneficiary info required");

        _transfer(msg.sender, recipient, amount);
        emit TravelRuleTransfer(msg.sender, recipient, amount, originatorInfo, beneficiaryInfo);
        return true;
    }

    // Disable the standard transfer functions.
    function transfer(address, uint256) public pure override returns (bool) {
        revert("Use transferWithTravelRule");
    }
    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("Use transferWithTravelRule");
    }
}
