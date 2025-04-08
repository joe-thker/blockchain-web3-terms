// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title InstitutionalInvestorVault
/// @notice Only approved institutional wallets can deposit/withdraw tokens.
contract InstitutionalInvestorVault is AccessControl {
    bytes32 public constant INSTITUTION_ROLE = keccak256("INSTITUTION_ROLE");
    IERC20 public immutable asset;

    mapping(address => uint256) public balances;

    event Deposited(address indexed institution, uint256 amount);
    event Withdrawn(address indexed institution, uint256 amount);

    constructor(address _asset) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        asset = IERC20(_asset);
    }

    /// @notice Deposit tokens into the vault (institutions only)
    function deposit(uint256 amount) external onlyRole(INSTITUTION_ROLE) {
        require(amount > 0, "Zero deposit");
        asset.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    /// @notice Withdraw previously deposited tokens
    function withdraw(uint256 amount) external onlyRole(INSTITUTION_ROLE) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        asset.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Admin can whitelist institutional wallet
    function addInstitution(address institution) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(INSTITUTION_ROLE, institution);
    }

    /// @notice Admin can revoke institutional status
    function removeInstitution(address institution) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(INSTITUTION_ROLE, institution);
    }
}
