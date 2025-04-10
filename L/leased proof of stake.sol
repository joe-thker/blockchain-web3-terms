// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Leased Proof of Stake Simulator
contract LeasedStaking {
    IERC20 public stakingToken;
    address public admin;

    struct Lease {
        uint256 amount;
        address validator;
    }

    mapping(address => Lease) public leases;
    mapping(address => uint256) public validatorPower;

    event Leased(address indexed user, address indexed validator, uint256 amount);
    event Unleased(address indexed user, address indexed validator, uint256 amount);

    constructor(address _token) {
        stakingToken = IERC20(_token);
        admin = msg.sender;
    }

    function leaseStake(address _validator, uint256 _amount) external {
        require(leases[msg.sender].amount == 0, "Already leasing");

        stakingToken.transferFrom(msg.sender, address(this), _amount);

        leases[msg.sender] = Lease({amount: _amount, validator: _validator});
        validatorPower[_validator] += _amount;

        emit Leased(msg.sender, _validator, _amount);
    }

    function unleaseStake() external {
        Lease memory lease = leases[msg.sender];
        require(lease.amount > 0, "No active lease");

        stakingToken.transfer(msg.sender, lease.amount);
        validatorPower[lease.validator] -= lease.amount;

        emit Unleased(msg.sender, lease.validator, lease.amount);
        delete leases[msg.sender];
    }

    function getValidatorPower(address _validator) external view returns (uint256) {
        return validatorPower[_validator];
    }
}

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
