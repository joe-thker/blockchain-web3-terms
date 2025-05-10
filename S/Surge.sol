// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// ------------------------------------------------------------------------
/// 1) Blob Submission
/// ------------------------------------------------------------------------
contract BlobSubmit {
    address public owner;
    mapping(address=>bool) public isRollup;
    uint256 public constant MAX_BLOB_SIZE = 1024; // max bytes per blob

    event BlobPosted(address indexed rollup, bytes data);

    modifier onlyRollup() {
        require(isRollup[msg.sender], "Not authorized rollup");
        _;
    }

    constructor() { owner = msg.sender; }

    // --- Attack: anyone posts arbitrary-sized data
    function postBlobInsecure(bytes calldata data) external {
        // no size or whitelist checks
        emit BlobPosted(msg.sender, data);
    }

    // --- Defense: only whitelisted + size limit
    function postBlobSecure(bytes calldata data) external onlyRollup {
        require(data.length <= MAX_BLOB_SIZE, "Blob too large");
        emit BlobPosted(msg.sender, data);
    }

    function setRollup(address rollup, bool ok) external {
        require(msg.sender == owner, "Not owner");
        isRollup[rollup] = ok;
    }
}

/// ------------------------------------------------------------------------
/// 2) Sequencer Scheduling
/// ------------------------------------------------------------------------
contract Sequencer is ReentrancyGuard {
    address public sequencer;
    uint256 public lastEpoch;          // epoch number
    uint256 public epochStart;         // timestamp of last epoch
    uint256 public minEpochInterval;   // seconds between epochs
    mapping(uint256=>uint256) public batchesThisEpoch;
    uint256 public maxBatchesPerEpoch;

    event BatchScheduled(uint256 indexed epoch, address by, bytes32 batchHash);

    modifier onlySequencer() {
        require(msg.sender == sequencer, "Not sequencer");
        _;
    }

    constructor(address _sequencer, uint256 _minInterval, uint256 _maxBatches) {
        sequencer         = _sequencer;
        minEpochInterval  = _minInterval;
        maxBatchesPerEpoch = _maxBatches;
        epochStart        = block.timestamp;
    }

    // --- Attack: anyone or reentrant call schedules unlimited batches
    function scheduleBatchInsecure(bytes32 batchHash) external {
        emit BatchScheduled(lastEpoch, msg.sender, batchHash);
    }

    // --- Defense: onlySequencer + rate limit + nonReentrant
    function scheduleBatchSecure(bytes32 batchHash) external onlySequencer nonReentrant {
        // start new epoch if needed
        if (block.timestamp >= epochStart + minEpochInterval) {
            lastEpoch++;
            epochStart = block.timestamp;
            batchesThisEpoch[lastEpoch] = 0;
        }
        require(batchesThisEpoch[lastEpoch] < maxBatchesPerEpoch, "Epoch batch limit");
        batchesThisEpoch[lastEpoch]++;
        emit BatchScheduled(lastEpoch, msg.sender, batchHash);
    }
}

/// ------------------------------------------------------------------------
/// 3) Fee Settlement
/// ------------------------------------------------------------------------
interface IPriceOracle {
    function latestTwap() external view returns (uint256 price, uint256 updatedAt);
}

contract FeeSettlement {
    address public owner;
    IPriceOracle[] public oracles;
    uint256 public staleAfter;           // seconds
    uint256 public maxFeesPerEpoch;      // cap bytes fees per epoch
    mapping(uint256=>uint256) public feesThisEpoch;
    uint256 public currentEpoch;

    event FeesCollected(uint256 indexed epoch, uint256 feeAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(
        IPriceOracle[] memory _oracles,
        uint256 _stale,
        uint256 _maxFees
    ) {
        owner = msg.sender;
        oracles = _oracles;
        staleAfter = _stale;
        maxFeesPerEpoch = _maxFees;
    }

    // --- Attack: use single oracle with flash price, no cap
    function collectFeesInsecure(uint256 blobSize) external returns(uint256) {
        // assume fee = blobSize * oracle price
        (uint256 p,) = oracles[0].latestTwap();
        uint256 fee = blobSize * p;
        emit FeesCollected(currentEpoch, fee);
        return fee;
    }

    // --- Defense: aggregate TWAP + stale check + epoch cap
    function collectFeesSecure(uint256 blobSize) external returns(uint256) {
        // aggregate TWAP
        uint256 sum;
        uint256 n = oracles.length;
        for (uint i; i < n; i++) {
            (uint256 p, uint256 t) = oracles[i].latestTwap();
            require(block.timestamp - t <= staleAfter, "Oracle stale");
            sum += p;
        }
        uint256 price = sum / n;
        uint256 fee = blobSize * price;

        // enforce per-epoch cap
        if (feesThisEpoch[currentEpoch] + fee > maxFeesPerEpoch) {
            revert("Epoch fee cap exceeded");
        }
        feesThisEpoch[currentEpoch] += fee;

        emit FeesCollected(currentEpoch, fee);
        return fee;
    }

    function advanceEpoch() external onlyOwner {
        currentEpoch++;
    }
}
