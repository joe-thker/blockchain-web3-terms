// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

/// @title TokenVesting - Secure and dynamic vesting period contract
contract TokenVesting {
    address public immutable token;
    address public immutable admin;
    uint256 public immutable cliffDuration;
    uint256 public immutable vestingDuration;
    uint256 public immutable startTime;

    struct Grant {
        uint256 totalAmount;
        uint256 claimedAmount;
    }

    mapping(address => Grant) public grants;

    event GrantAssigned(address indexed beneficiary, uint256 totalAmount);
    event TokensClaimed(address indexed beneficiary, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(
        address _token,
        uint256 _cliffDuration,
        uint256 _vestingDuration
    ) {
        require(_vestingDuration > _cliffDuration, "Invalid durations");
        token = _token;
        admin = msg.sender;
        cliffDuration = _cliffDuration;
        vestingDuration = _vestingDuration;
        startTime = block.timestamp;
    }

    function assignGrant(address beneficiary, uint256 amount) external onlyAdmin {
        require(grants[beneficiary].totalAmount == 0, "Grant already exists");
        grants[beneficiary] = Grant({
            totalAmount: amount,
            claimedAmount: 0
        });
        emit GrantAssigned(beneficiary, amount);
    }

    function claim() external {
        Grant storage g = grants[msg.sender];
        require(g.totalAmount > 0, "No grant");

        uint256 vested = _vestedAmount(msg.sender);
        require(vested > g.claimedAmount, "Nothing to claim");

        uint256 claimable = vested - g.claimedAmount;
        g.claimedAmount = vested;

        bool sent = IERC20(token).transfer(msg.sender, claimable);
        require(sent, "Transfer failed");

        emit TokensClaimed(msg.sender, claimable);
    }

    function _vestedAmount(address user) internal view returns (uint256) {
        Grant memory g = grants[user];

        if (block.timestamp < startTime + cliffDuration) {
            return 0;
        }

        uint256 elapsed = block.timestamp - startTime;

        if (elapsed >= vestingDuration) {
            return g.totalAmount;
        }

        return (g.totalAmount * elapsed) / vestingDuration;
    }

    function getClaimable(address user) external view returns (uint256) {
        Grant memory g = grants[user];
        uint256 vested = _vestedAmount(user);
        return vested > g.claimedAmount ? (vested - g.claimedAmount) : 0;
    }
}
