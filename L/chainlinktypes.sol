// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/// @title Chainlink Use Cases
/// @notice Examples of core Chainlink services implemented in Solidity

/// 1. Chainlink Price Feed
contract ChainlinkPriceFeed {
    AggregatorV3Interface internal priceFeed;

    constructor(address _feed) {
        priceFeed = AggregatorV3Interface(_feed);
    }

    function getLatestPrice() external view returns (int256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        return price;
    }
}

/// 2. Chainlink API Consumer (External Data Fetch)
contract ChainlinkAPIConsumer is ChainlinkClient {
    using Chainlink for Chainlink.Request;
    uint256 public data;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    constructor(address _oracle, string memory _jobId, address _link) {
        setChainlinkToken(_link);
        setChainlinkOracle(_oracle);
        oracle = _oracle;
        jobId = stringToBytes32(_jobId);
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }

    function requestData(string memory url, string memory path) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.add("get", url);
        req.add("path", path);
        return sendChainlinkRequest(req, fee);
    }

    function fulfill(bytes32 _requestId, uint256 _data) public recordChainlinkFulfillment(_requestId) {
        data = _data;
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }
}

/// 3. Chainlink VRF v2 (Verifiable Randomness)
contract ChainlinkVRFExampleV2 is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 public subscriptionId;
    address public vrfCoordinator;
    bytes32 public keyHash;
    uint256 public randomResult;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    uint256 public requestId;

    constructor(address _vrfCoordinator, bytes32 _keyHash, uint64 _subId)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        vrfCoordinator = _vrfCoordinator;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subId;
    }

    function requestRandomWords() external {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        randomResult = randomWords[0];
    }
}

/// 4. Chainlink Keeper-Compatible Automation (Ping Example)
interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata) external returns (bool upkeepNeeded, bytes memory);
    function performUpkeep(bytes calldata) external;
}

contract ChainlinkKeeperPing is KeeperCompatibleInterface {
    uint256 public lastTimestamp;
    uint256 public interval;

    constructor(uint256 _interval) {
        interval = _interval;
        lastTimestamp = block.timestamp;
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (block.timestamp - lastTimestamp) > interval;
    }

    function performUpkeep(bytes calldata) external override {
        require((block.timestamp - lastTimestamp) > interval, "Too early");
        lastTimestamp = block.timestamp;
    }
}