// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WhiteLabelStakingFactory {
    address[] public vaults;
    event VaultDeployed(address indexed vault, address token, uint256 rewardRate, string brand);

    function deployVault(address token, uint256 rewardRatePerSec, string calldata brand) external returns (address) {
        bytes32 salt = keccak256(abi.encode(token, msg.sender));
        bytes memory code = type(StakingVault).creationCode;

        address vault;
        assembly {
            vault := create2(0, add(code, 32), mload(code), salt)
        }

        StakingVault(vault).initialize(token, rewardRatePerSec, msg.sender, brand);
        vaults.push(vault);

        emit VaultDeployed(vault, token, rewardRatePerSec, brand);
        return vault;
    }

    function getVaults() external view returns (address[] memory) {
        return vaults;
    }
}
