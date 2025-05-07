// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SolverSuite
/// @notice PuzzleSolver, ArbSolver, and RouteSolver patterns with insecure vs. secure methods

abstract contract Base {
    address public owner;
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
    constructor() { owner = msg.sender; }
}

/// Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

//////////////////////////////////////////////////////
// 1) Puzzle Solver
//////////////////////////////////////////////////////
contract PuzzleSolver is Base {
    bytes32 public puzzle;           // hash challenge
    uint256 public target;           // difficulty target
    mapping(bytes32=>bool) used;     // prevent replays

    constructor(bytes32 _puzzle, uint256 _target) {
        puzzle = _puzzle;
        target = _target;
    }

    // --- Attack: accept any preimage
    function solveInsecure(bytes32 solution) external {
        // no difficulty or replay check
        require(keccak256(abi.encodePacked(solution)) == puzzle, "Bad sol");
        // reward solver...
        payable(msg.sender).transfer(address(this).balance);
    }

    // --- Defense: require difficulty + replay protection
    function solveSecure(bytes32 solution) external nonReentrant {
        bytes32 h = keccak256(abi.encodePacked(solution));
        require(h == puzzle,           "Bad sol");
        require(uint256(h) < target,   "Low difficulty");
        require(!used[h],              "Already used");
        used[h] = true;
        // reward solver
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}

//////////////////////////////////////////////////////
// 2) Arbitrage Solver
//////////////////////////////////////////////////////
interface IPriceOracle {
    function getPrice(address token) external view returns (uint256);
}

contract ArbSolver is Base, ReentrancyGuard {
    IPriceOracle public oracleA;
    IPriceOracle public oracleB;
    uint256 public maxGasPrice;

    constructor(IPriceOracle _a, IPriceOracle _b, uint256 _maxGas) {
        oracleA      = _a;
        oracleB      = _b;
        maxGasPrice  = _maxGas;
    }

    // --- Attack: public oracles + unbounded gas price
    function arbInsecure(address token, uint256 amount) external {
        require(tx.gasprice <= type(uint256).max, "no cap");
        uint256 pA = oracleA.getPrice(token);
        uint256 pB = oracleB.getPrice(token);
        if (pA < pB) {
            // buy on A, sell on B
            // ...
        }
        // profit to caller...
    }

    // --- Defense: TWAP + gasprice cap
    function arbSecure(address token, uint256 amount) external nonReentrant {
        require(tx.gasprice <= maxGasPrice, "Gas too high");
        // assume TWAP: average of both oracles
        uint256 p1 = oracleA.getPrice(token);
        uint256 p2 = oracleB.getPrice(token);
        uint256 price = (p1 + p2) / 2;
        // simple check for arbitrage window
        if (price * 99 / 100 > p1) { // require ≥1% profit
            // execute arbitrage logic...
        } else {
            revert("No arb opp");
        }
    }
}

//////////////////////////////////////////////////////
// 3) Route Solver
//////////////////////////////////////////////////////
interface IDEX {
    function getRate(address inTok, address outTok, uint256 amt) external view returns (uint256);
    function swap(address inTok, address outTok, uint256 amtIn, uint256 minOut) external returns (uint256);
}

contract RouteSolver is Base {
    IDEX[] public dexs;
    uint256 public maxHops;

    constructor(IDEX[] memory _dexs, uint256 _maxHops) {
        dexs    = _dexs;
        maxHops = _maxHops;
    }

    // --- Attack: unbounded loops → DoS & no per-hop checks
    function findAndSwapInsecure(
        address[] calldata path,
        uint256 amountIn
    ) external {
        uint256 amt = amountIn;
        for (uint i = 0; i < path.length - 1; i++) {
            amt = dexs[i].swap(path[i], path[i+1], amt, 0);
        }
        // send final amt to caller...
    }

    // --- Defense: limit hops + per-hop slippage
    function findAndSwapSecure(
        address[] calldata path,
        uint256 amountIn,
        uint256[] calldata minOuts
    ) external {
        require(path.length - 1 <= maxHops, "Too many hops");
        require(minOuts.length == path.length - 1, "Bad mins");
        uint256 amt = amountIn;
        for (uint i = 0; i < path.length - 1; i++) {
            // compute rate check
            uint256 rate = dexs[i].getRate(path[i], path[i+1], amt);
            require(rate >= minOuts[i], "Slippage at hop");
            // perform swap
            amt = dexs[i].swap(path[i], path[i+1], amt, minOuts[i]);
        }
        // transfer final amt to caller
        payable(msg.sender).transfer(amt);
    }

    receive() external payable {}
}
