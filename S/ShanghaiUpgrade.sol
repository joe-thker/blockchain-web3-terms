// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ShanghaiUpgradeSuite
/// @notice UUPS Proxy Upgrade, Withdrawal Vault, and Governance Timelock
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// 1) UUPS Proxy Upgrade
contract ProxyUpgradeable is Base {
    // Storage slot for implementation per EIP-1967
    bytes32 internal constant _IMPLEMENTATION_SLOT = 
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    // --- Attack: anyone can upgrade implementation
    function upgradeToInsecure(address newImpl) external {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImpl)
        }
    }

    // --- Defense: onlyOwner + validate code hash
    function upgradeToSecure(address newImpl, bytes32 expectedCodeHash) external onlyOwner {
        // validate that newImpl’s runtime code matches expected
        bytes32 codeHash;
        assembly { codeHash := extcodehash(newImpl) }
        require(codeHash == expectedCodeHash, "Bad implementation");
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImpl)
        }
    }

    // Fallback to delegate to implementation
    fallback() external payable {
        assembly {
            let impl := sload(_IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result case 0 { revert(0, returndatasize()) }
                          default { return(0, returndatasize()) }
        }
    }
}

/// 2) Withdrawal Vault Module
contract WithdrawalVault is Base, ReentrancyGuard {
    mapping(address => uint256) public entitled;    // validator → amount
    mapping(address => uint256) public claimed;     // validator → already claimed

    // Seed entitled balances (onlyOwner)
    function seedEntitlements(address[] calldata vals, uint256[] calldata amounts) external onlyOwner {
        require(vals.length == amounts.length, "Length mismatch");
        for (uint i = 0; i < vals.length; i++) {
            entitled[vals[i]] = amounts[i];
        }
    }

    // --- Attack: naive claim allows reentrancy & over-claim
    function claimWithdrawalInsecure() external {
        uint256 total = entitled[msg.sender];
        require(total > 0, "No entitlement");
        // no CEI: state is updated after transfer
        payable(msg.sender).call{ value: total }("");
    }

    // --- Defense: CEI + nonReentrant + cap enforcement
    function claimWithdrawalSecure() external nonReentrant {
        uint256 total = entitled[msg.sender];
        require(total > 0, "No entitlement");
        uint256 already = claimed[msg.sender];
        uint256 toClaim = total - already;
        require(toClaim > 0, "Nothing left");
        // Effects
        claimed[msg.sender] = total;
        // Interaction with limited gas
        (bool ok, ) = payable(msg.sender).call{ value: toClaim, gas: 2300 }("");
        require(ok, "Transfer failed");
    }

    // Fallback receive to accept ETH
    receive() external payable {}
}

/// 3) Governance Timelock Executor
contract GovernanceTimelock is Base {
    uint256 public delay;      // seconds
    mapping(bytes32 => bool) public queued;

    event Queued(bytes32 id, address target, uint256 value, bytes data, uint256 eta);
    event Executed(bytes32 id, address target, uint256 value, bytes data);

    constructor(uint256 _delay) {
        delay = _delay;
    }

    // --- Attack: immediate execution, no delay
    function executeInsecure(address target, uint256 value, bytes calldata data) external {
        // no delay enforced
        (bool ok, ) = target.call{ value: value }(data);
        require(ok, "Call failed");
    }

    // --- Defense: queue + enforce eta + onlyOwner
    function queueSecure(address target, uint256 value, bytes calldata data) external onlyOwner returns (bytes32) {
        uint256 eta = block.timestamp + delay;
        bytes32 id = keccak256(abi.encode(target, value, data, eta));
        require(!queued[id], "Already queued");
        queued[id] = true;
        emit Queued(id, target, value, data, eta);
        return id;
    }

    function executeSecure(address target, uint256 value, bytes calldata data, uint256 eta) external onlyOwner {
        bytes32 id = keccak256(abi.encode(target, value, data, eta));
        require(queued[id], "Not queued");
        require(block.timestamp >= eta, "Too early");
        // delete before call to prevent re-executes
        queued[id] = false;
        (bool ok, ) = target.call{ value: value }(data);
        require(ok, "Call failed");
        emit Executed(id, target, value, data);
    }

    // Allow ETH deposits for queued calls
    receive() external payable {}
}
