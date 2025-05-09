// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title SupercycleSuite
/// @notice Modules: EpochManager, SupercycleRewards, ParamUpdater

///////////////////////////////////////////////////////////////////////////
// 1) Epoch Management
///////////////////////////////////////////////////////////////////////////
contract EpochManager {
    address public owner;
    uint256 public currentEpoch;
    uint256 public lastStart;
    uint256 public minInterval; // e.g. 30 days

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    event EpochStarted(uint256 epoch, uint256 timestamp);

    constructor(uint256 _minInterval) {
        owner       = msg.sender;
        minInterval = _minInterval;
    }

    // --- Insecure: anyone starts epoch anytime
    function startEpochInsecure() external {
        currentEpoch++;
        lastStart = block.timestamp;
        emit EpochStarted(currentEpoch, block.timestamp);
    }

    // --- Secure: onlyOwner + enforce minimum interval
    function startEpochSecure() external onlyOwner {
        require(
            block.timestamp >= lastStart + minInterval,
            "Too early to start next epoch"
        );
        currentEpoch++;
        lastStart = block.timestamp;
        emit EpochStarted(currentEpoch, block.timestamp);
    }
}

///////////////////////////////////////////////////////////////////////////
// 2) Supercycle Rewards
///////////////////////////////////////////////////////////////////////////
contract SupercycleRewards is EpochManager, ReentrancyGuard {
    uint256 public rewardAmount;
    mapping(address => mapping(uint256 => bool)) public claimed; // user → epoch → claimed

    event Claimed(address indexed user, uint256 epoch, uint256 amount);

    constructor(uint256 _minInterval, uint256 _reward)
        EpochManager(_minInterval)
    {
        rewardAmount = _reward;
    }

    // --- Insecure: user can claim multiple times per epoch
    function claimInsecure() external {
        require(currentEpoch > 0, "Epoch not started");
        // no check for prior claim
        payable(msg.sender).transfer(rewardAmount);
        emit Claimed(msg.sender, currentEpoch, rewardAmount);
    }

    // --- Secure: one claim per user per epoch + nonReentrant
    function claimSecure() external nonReentrant {
        uint256 e = currentEpoch;
        require(e > 0, "Epoch not started");
        require(!claimed[msg.sender][e], "Already claimed this epoch");
        claimed[msg.sender][e] = true;
        payable(msg.sender).transfer(rewardAmount);
        emit Claimed(msg.sender, e, rewardAmount);
    }

    // Fund the contract to pay rewards
    receive() external payable {}
}

///////////////////////////////////////////////////////////////////////////
// 3) Parameter Updates per Supercycle
///////////////////////////////////////////////////////////////////////////
contract ParamUpdater is EpochManager {
    // protocol parameter (e.g. fee rate in BP)
    uint256 public feeBP;
    uint256 public lastUpdateEpoch;
    uint256 public version;

    event ParamUpdated(uint256 version, uint256 epoch, uint256 newFeeBP);

    constructor(uint256 _minInterval, uint256 initialFeeBP)
        EpochManager(_minInterval)
    {
        feeBP = initialFeeBP;
        version = 1;
    }

    // --- Insecure: anyone or owner can update anytime, even within same epoch
    function updateFeeInsecure(uint256 newFeeBP) external {
        feeBP = newFeeBP;
        version++;
    }

    // --- Secure: onlyOwner + only once per epoch + monotonic version
    function updateFeeSecure(uint256 newFeeBP) external onlyOwner {
        uint256 e = currentEpoch;
        require(e > 0, "Epoch not started");
        require(e > lastUpdateEpoch, "Already updated this epoch");
        feeBP = newFeeBP;
        lastUpdateEpoch = e;
        version++;
        emit ParamUpdated(version, e, newFeeBP);
    }
}
