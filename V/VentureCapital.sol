// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VentureVestingVault - Secure VC token vesting vault
contract VentureVestingVault {
    address public immutable token;
    address public immutable admin;
    uint256 public immutable cliffEnd;
    uint256 public immutable vestingDuration;

    struct Grant {
        uint256 total;
        uint256 claimed;
        uint256 start;
    }

    mapping(address => Grant) public grants;
    mapping(address => bool) public vcWhitelist;

    event Vested(address indexed vc, uint256 amount);
    event Whitelisted(address indexed vc);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyWhitelisted() {
        require(vcWhitelist[msg.sender], "Not whitelisted VC");
        _;
    }

    constructor(address _token, uint256 _cliff, uint256 _vesting) {
        admin = msg.sender;
        token = _token;
        cliffEnd = block.timestamp + _cliff;
        vestingDuration = _vesting;
    }

    function whitelistVC(address vc, uint256 amount) external onlyAdmin {
        require(!vcWhitelist[vc], "Already whitelisted");
        vcWhitelist[vc] = true;
        grants[vc] = Grant({
            total: amount,
            claimed: 0,
            start: cliffEnd
        });
        emit Whitelisted(vc);
    }

    function claim() external onlyWhitelisted {
        Grant storage g = grants[msg.sender];
        require(block.timestamp >= g.start, "Cliff not passed");

        uint256 vested = vestedAmount(g);
        require(vested > g.claimed, "Nothing to claim");

        uint256 claimable = vested - g.claimed;
        g.claimed = vested;

        bool ok = IERC20(token).transfer(msg.sender, claimable);
        require(ok, "Transfer failed");

        emit Vested(msg.sender, claimable);
    }

    function vestedAmount(Grant memory g) public view returns (uint256) {
        if (block.timestamp < g.start) return 0;
        if (block.timestamp >= g.start + vestingDuration) return g.total;
        return (g.total * (block.timestamp - g.start)) / vestingDuration;
    }

    function getClaimable(address vc) external view returns (uint256) {
        Grant memory g = grants[vc];
        uint256 vested = vestedAmount(g);
        return vested > g.claimed ? (vested - g.claimed) : 0;
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}
