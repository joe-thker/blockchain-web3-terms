// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

////////////////////////////////////////////////////////////////////////////////
// 1) External Library Invocation
////////////////////////////////////////////////////////////////////////////////
contract LibUserInsecure {
    address public lib;  // upgradable by anyone

    function setLibrary(address _lib) external {
        lib = _lib;
    }

    // --- Attack: delegatecall to untrusted lib
    function doWork(bytes calldata data) external {
        (bool ok, ) = lib.delegatecall(data);
        require(ok, "delegatecall failed");
    }
}

contract LibUserSecure {
    address public immutable LIB;  // locked at deploy
    bytes32  public immutable LIB_CODEHASH;

    constructor(address _lib) {
        LIB = _lib;
        bytes32 h;
        assembly { h := extcodehash(_lib) }
        LIB_CODEHASH = h;
    }

    // --- Defense: verify codehash before each call
    function doWorkSecure(bytes calldata data) external {
        bytes32 h;
        assembly { h := extcodehash(LIB) }
        require(h == LIB_CODEHASH, "Library code changed");
        (bool ok, ) = LIB.delegatecall(data);
        require(ok, "delegatecall failed");
    }
}

////////////////////////////////////////////////////////////////////////////////
// 2) Upgradeable Proxy Initialization
////////////////////////////////////////////////////////////////////////////////
contract ProxyInsecure {
    address public admin;
    address public implementation;

    // Missing initializer guard: anyone can call
    function initialize(address _impl) external {
        admin = msg.sender;
        implementation = _impl;
    }
}

contract ProxySecure {
    address public admin;
    address public implementation;
    uint8   private initialized;  // 0 = not, 1 = done

    modifier initializer() {
        require(initialized == 0, "Already initialized");
        initialized = 1;
        _;
    }

    function initialize(address _impl) external initializer {
        admin = msg.sender;
        implementation = _impl;
    }

    function upgradeTo(address _impl) external {
        require(msg.sender == admin, "Not admin");
        implementation = _impl;
    }
}

////////////////////////////////////////////////////////////////////////////////
// 3) Dependency-fed Oracle
////////////////////////////////////////////////////////////////////////////////
interface IOracle {
    function latestData() external view returns (uint256 value, uint256 updatedAt);
}

contract OracleUserInsecure {
    IOracle public oracle;

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
    }

    // --- Attack: single oracle can be poisoned
    function readValue() external view returns (uint256) {
        (uint256 v,) = oracle.latestData();
        return v;
    }
}

contract OracleUserSecure {
    IOracle[] public oracles;
    uint256 public staleAfter; // seconds

    constructor(address[] memory _oracles, uint256 _stale) {
        oracles   = new IOracle[](_oracles.length);
        for (uint i = 0; i < _oracles.length; i++) {
            oracles[i] = IOracle(_oracles[i]);
        }
        staleAfter = _stale;
    }

    // --- Defense: median-of-three + freshness check
    function readValueSecure() external view returns (uint256) {
        uint n = oracles.length;
        require(n > 0, "No oracles");
        uint[] memory vals = new uint[](n);
        for (uint i = 0; i < n; i++) {
            (uint v, uint t) = oracles[i].latestData();
            require(block.timestamp - t <= staleAfter, "Oracle stale");
            vals[i] = v;
        }
        // simple sort to pick median
        for (uint i = 0; i < n; i++) {
            for (uint j = i + 1; j < n; j++) {
                if (vals[j] < vals[i]) {
                    (vals[i], vals[j]) = (vals[j], vals[i]);
                }
            }
        }
        return vals[n / 2];
    }
}
