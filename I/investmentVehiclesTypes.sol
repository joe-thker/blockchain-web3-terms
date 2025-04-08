// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// 1. Vault Investment Vehicle
contract VaultVehicle is Ownable {
    mapping(address => uint256) public balances;

    constructor() Ownable(msg.sender) {}

    function deposit() external payable {
        require(msg.value > 0, "No ETH");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}

/// 2. Tokenized Fund Pool
contract FundPoolVehicle is ERC20, Ownable {
    IERC20 public asset;

    constructor(address _asset) ERC20("Fund Pool Share", "FPS") Ownable(msg.sender) {
        asset = IERC20(_asset);
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Invalid");
        uint256 shares = totalSupply() == 0 ? amount : (amount * totalSupply()) / asset.balanceOf(address(this));
        asset.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, shares);
    }

    function withdraw(uint256 shares) external {
        require(balanceOf(msg.sender) >= shares, "Too many shares");
        uint256 amount = (shares * asset.balanceOf(address(this))) / totalSupply();
        _burn(msg.sender, shares);
        asset.transfer(msg.sender, amount);
    }
}

/// 3. Indexed Portfolio Vehicle
contract IndexedPortfolio is Ownable {
    IERC20[] public assets;
    uint256[] public weights;

    constructor(IERC20[] memory _assets, uint256[] memory _weights) Ownable(msg.sender) {
        require(_assets.length == _weights.length, "Mismatch");
        assets = _assets;
        weights = _weights;
    }

    function rebalance() external onlyOwner {
        // Just a stub — real rebalancing logic would go here
    }
}

/// 4. Yield Aggregator
contract YieldAggregator is Ownable {
    mapping(address => uint256) public deposits;
    uint256 public totalDeposits;

    constructor() Ownable(msg.sender) {}

    function deposit() external payable {
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    function distributeYield() external onlyOwner {
        uint256 yield = address(this).balance - totalDeposits;
        for (uint256 i = 0; i < 10; i++) {
            // simulate top 10 users — real system would track them
        }
    }

    receive() external payable {}
}

/// 5. Risk/Insurance Pool
contract InsuranceFund is Ownable {
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public claims;

    constructor() Ownable(msg.sender) {}

    function contribute() external payable {
        require(msg.value > 0, "No ETH");
        contributions[msg.sender] += msg.value;
    }

    function fileClaim(uint256 amount) external {
        require(amount <= contributions[msg.sender] / 2, "Max 50%");
        claims[msg.sender] = amount;
    }

    function approveClaim(address claimant) external onlyOwner {
        uint256 amount = claims[claimant];
        claims[claimant] = 0;
        payable(claimant).transfer(amount);
    }

    receive() external payable {}
}

/// 6. DAO Treasury Vehicle
contract DAOTreasuryVehicle is Ownable {
    struct Proposal {
        string description;
        address payable recipient;
        uint256 amount;
        uint256 votes;
        bool executed;
    }

    Proposal[] public proposals;
    mapping(address => bool) public hasVoted;

    constructor() Ownable(msg.sender) {}

    function submitProposal(string memory desc, address payable recipient, uint256 amount) external onlyOwner {
        proposals.push(Proposal(desc, recipient, amount, 0, false));
    }

    function vote(uint256 index) external {
        require(!hasVoted[msg.sender], "Already voted");
        proposals[index].votes++;
        hasVoted[msg.sender] = true;
    }

    function execute(uint256 index) external onlyOwner {
        Proposal storage p = proposals[index];
        require(!p.executed && p.votes > 0, "Invalid");
        p.executed = true;
        p.recipient.transfer(p.amount);
    }

    receive() external payable {}
}
