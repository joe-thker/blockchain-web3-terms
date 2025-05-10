// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SybilAttackModule - Attack and Defense Simulation for Sybil Attacks in Web3

// ==============================
// 🔓 ATTACK CONTRACT
// ==============================

interface IAirdrop {
    function claim() external;
}

contract SybilAirdropAttacker {
    IAirdrop public target;

    constructor(address _target) {
        target = IAirdrop(_target);
    }

    function attack() external {
        for (uint256 i = 0; i < 10; i++) {
            address clone = deployWallet(i);
            // simulate sending ETH or gas if needed
            AirdropClaimWallet(clone).claimFrom(target);
        }
    }

    function deployWallet(uint256 salt) internal returns (address clone) {
        bytes memory bytecode = type(AirdropClaimWallet).creationCode;
        bytes32 saltHash = keccak256(abi.encodePacked(salt));
        assembly {
            clone := create2(0, add(bytecode, 32), mload(bytecode), saltHash)
        }
    }
}

contract AirdropClaimWallet {
    function claimFrom(IAirdrop target) external {
        target.claim();
    }
}

// ==============================
// 🔐 DEFENSE CONTRACT
// ==============================

interface IZkID {
    function isVerified(address user) external view returns (bool);
}

contract SybilResistantAirdrop {
    mapping(address => bool) public hasClaimed;
    IZkID public zkID;
    uint256 public totalClaimed;

    event Claimed(address indexed user, uint256 amount);

    constructor(address _zkID) {
        zkID = IZkID(_zkID);
    }

    function claim() external {
        require(zkID.isVerified(msg.sender), "Not verified identity");
        require(!hasClaimed[msg.sender], "Already claimed");

        hasClaimed[msg.sender] = true;
        totalClaimed += 1;

        payable(msg.sender).transfer(0.01 ether);
        emit Claimed(msg.sender, 0.01 ether);
    }

    receive() external payable {}
}

// ==============================
// 🧪 MOCK ZK-ID CONTRACT
// ==============================

contract MockZkID is IZkID {
    mapping(address => bool) public verifiedUsers;

    function verify(address user) external {
        verifiedUsers[user] = true;
    }

    function isVerified(address user) external view override returns (bool) {
        return verifiedUsers[user];
    }
}
