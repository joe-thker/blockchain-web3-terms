// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title InteroperabilityTypes
/// @notice Shows types of interoperability models in Solidity-based smart contracts

/// 1. Token Standard Interoperability (ERC20)
contract TokenStandardInterop {
    event TokenAccepted(address indexed from, address indexed token, uint256 amount);

    function acceptERC20(address token, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit TokenAccepted(msg.sender, token, amount);
    }
}

/// 2. Oracle-Based Interoperability (Chainlink Example)
contract OracleInterop {
    AggregatorV3Interface public priceFeed;

    constructor(address _oracle) {
        priceFeed = AggregatorV3Interface(_oracle);
    }

    function getPrice() external view returns (int256) {
        (, int256 price, , ,) = priceFeed.latestRoundData();
        return price;
    }
}

/// 3. Cross-Contract Interoperability
interface IExternalLogic {
    function compute(uint256 x) external pure returns (uint256);
}

contract ContractInterop {
    address public externalContract;

    constructor(address _contract) {
        externalContract = _contract;
    }

    function getComputedValue(uint256 val) external view returns (uint256) {
        return IExternalLogic(externalContract).compute(val);
    }
}

/// 4. Fallback/Router Interoperability
contract RouterInterop {
    event Routed(string command, uint256 amount);

    fallback() external payable {
        emit Routed("fallback", msg.value);
    }

    receive() external payable {
        emit Routed("receive", msg.value);
    }
}

/// 5. Bridged Asset Lock (simplified cross-chain asset escrow)
contract BridgeLock {
    address public owner;
    mapping(address => uint256) public balances;

    event Locked(address indexed user, uint256 amount);
    event Released(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function lock() external payable {
        require(msg.value > 0, "No ETH sent");
        balances[msg.sender] += msg.value;
        emit Locked(msg.sender, msg.value);
    }

    function release(address to, uint256 amount) external {
        require(msg.sender == owner, "Not authorized");
        require(address(this).balance >= amount, "Insufficient balance");
        payable(to).transfer(amount);
        emit Released(to, amount);
    }
}
