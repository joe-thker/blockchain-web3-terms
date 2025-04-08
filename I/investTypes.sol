// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// 1. Vault Investment
contract VaultInvestment is Ownable {
    uint256 public totalShares;
    mapping(address => uint256) public shares;

    constructor() Ownable(msg.sender) {}

    function invest() external payable {
        require(msg.value > 0, "No ETH sent");
        uint256 newShares = totalShares == 0 ? msg.value : (msg.value * totalShares) / address(this).balance;
        shares[msg.sender] += newShares;
        totalShares += newShares;
    }

    function withdraw() external {
        uint256 userShares = shares[msg.sender];
        require(userShares > 0, "No shares");
        uint256 payout = (address(this).balance * userShares) / totalShares;
        totalShares -= userShares;
        shares[msg.sender] = 0;
        payable(msg.sender).transfer(payout);
    }

    receive() external payable {}
}

/// 2. Token Sale (IDO/ICO)
contract TokenSale is ERC20, Ownable {
    uint256 public pricePerToken = 1e15; // 0.001 ETH per token

    constructor() ERC20("Presale Token", "PST") Ownable(msg.sender) {}

    function buyTokens() external payable {
        require(msg.value > 0, "Send ETH");
        uint256 amount = (msg.value * 1e18) / pricePerToken;
        _mint(msg.sender, amount);
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

/// 3. Lending Investment
contract LendingPool is Ownable {
    mapping(address => uint256) public deposits;
    uint256 public totalDeposits;

    constructor() Ownable(msg.sender) {}

    function deposit() external payable {
        require(msg.value > 0, "No ETH");
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    function withdraw() external {
        uint256 amount = deposits[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        deposits[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}

/// 4. DAO Investment
contract DAOInvestment is Ownable {
    struct Proposal {
        string name;
        address payable recipient;
        uint256 amount;
        uint256 votes;
        bool executed;
    }

    Proposal[] public proposals;
    mapping(address => bool) public voters;

    constructor() Ownable(msg.sender) {}

    function createProposal(string memory name, address payable recipient, uint256 amount) external onlyOwner {
        proposals.push(Proposal(name, recipient, amount, 0, false));
    }

    function vote(uint256 index) external {
        require(!voters[msg.sender], "Already voted");
        proposals[index].votes += 1;
        voters[msg.sender] = true;
    }

    function execute(uint256 index) external onlyOwner {
        Proposal storage p = proposals[index];
        require(!p.executed && p.votes > 0, "Invalid");
        p.executed = true;
        p.recipient.transfer(p.amount);
    }

    receive() external payable {}
}

/// 5. NFT/GameFi Investment (Stake-to-Earn Model)
interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract NFTStakingInvestment is Ownable {
    struct StakeInfo {
        address owner;
        uint256 timestamp;
    }

    mapping(uint256 => StakeInfo) public stakes;
    address public nftAddress;
    uint256 public rewardRate = 1e16; // 0.01 ETH per day

    constructor(address _nft) Ownable(msg.sender) {
        nftAddress = _nft;
    }

    function stake(uint256 tokenId) external {
        IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);
        stakes[tokenId] = StakeInfo(msg.sender, block.timestamp);
    }

    function unstake(uint256 tokenId) external {
        StakeInfo memory info = stakes[tokenId];
        require(info.owner == msg.sender, "Not owner");
        uint256 reward = ((block.timestamp - info.timestamp) / 1 days) * rewardRate;
        delete stakes[tokenId];
        payable(msg.sender).transfer(reward);
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);
    }

    receive() external payable {}
}
