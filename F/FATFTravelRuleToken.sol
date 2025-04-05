// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FATFTravelRuleToken
 * @dev ERC20 token that requires FATF Travel Rule data on every transfer.
 * Transfers must be done via transferWithTravelRule which requires originator and beneficiary information.
 * Standard transfer and transferFrom functions are disabled.
 */
contract FATFTravelRuleToken is ERC20, Ownable {
    // Emitted on every travel rule compliant transfer.
    event TravelRuleTransfer(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        string originatorInfo,
        string beneficiaryInfo
    );

    /**
     * @dev Constructor mints the initial supply to the deployer.
     * @param initialSupply Total token supply in the smallest unit (e.g., wei).
     */
    constructor(uint256 initialSupply)
        ERC20("FATF Travel Rule Token", "FTRT")
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Transfers tokens along with the required FATF Travel Rule data.
     * The caller must provide both originatorInfo and beneficiaryInfo.
     * @param recipient The address receiving tokens.
     * @param amount The token amount to transfer.
     * @param originatorInfo Additional required data for the sender (e.g., KYC ID).
     * @param beneficiaryInfo Additional required data for the recipient.
     * @return success True if the transfer succeeds.
     */
    function transferWithTravelRule(
        address recipient,
        uint256 amount,
        string calldata originatorInfo,
        string calldata beneficiaryInfo
    ) external returns (bool success) {
        require(bytes(originatorInfo).length > 0, "Originator info required");
        require(bytes(beneficiaryInfo).length > 0, "Beneficiary info required");

        // Perform the token transfer using the internal _transfer function.
        _transfer(msg.sender, recipient, amount);

        // Emit event with travel rule data so that off-chain systems can process the information.
        emit TravelRuleTransfer(msg.sender, recipient, amount, originatorInfo, beneficiaryInfo);
        return true;
    }

    /**
     * @dev Disable the standard transfer function.
     */
    function transfer(address, uint256) public pure override returns (bool) {
        revert("Use transferWithTravelRule");
    }

    /**
     * @dev Disable the standard transferFrom function.
     */
    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("Use transferWithTravelRule");
    }
}
