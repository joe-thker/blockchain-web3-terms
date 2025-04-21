// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PaidOpenSource is Ownable {
    struct Project {
        address owner;
        string  name;
        string  repoUrl;
        string  description;
        uint256 registeredAt;
        bool    active;
    }

    uint256 private _nextId = 1;
    uint256 public  fee = 0.01 ether;
    mapping(uint256 => Project) private _projects;
    mapping(address => uint256[]) private _ownerToProjects;

    event ProjectRegistered(uint256 indexed id, address indexed owner);
    event ProjectUpdated(uint256 indexed id);
    event Withdrawn(address to, uint256 amount);

    constructor() Ownable(msg.sender) {}

    /// Owner can update the fee
    function setFee(uint256 newFee) external onlyOwner {
        fee = newFee;
    }

    /// Withdraw collected fees
    function withdrawFees(address payable to) external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "No funds");
        to.transfer(bal);
        emit Withdrawn(to, bal);
    }

    /// Register (pay fee)
    function registerProject(
        string calldata name,
        string calldata repoUrl,
        string calldata description
    ) external payable returns (uint256 projectId) {
        require(msg.value >= fee, "Insufficient fee");
        require(bytes(name).length > 0, "Name required");
        require(bytes(repoUrl).length > 0, "Repo URL required");

        projectId = _nextId++;
        _projects[projectId] = Project({
            owner: msg.sender,
            name: name,
            repoUrl: repoUrl,
            description: description,
            registeredAt: block.timestamp,
            active: true
        });
        _ownerToProjects[msg.sender].push(projectId);

        // refund excess
        if (msg.value > fee) payable(msg.sender).transfer(msg.value - fee);

        emit ProjectRegistered(projectId, msg.sender);
    }

    /// Update metadata (pay fee)
    function updateProject(
        uint256 projectId,
        string calldata name,
        string calldata repoUrl,
        string calldata description
    ) external payable {
        require(msg.value >= fee, "Insufficient fee");
        Project storage p = _projects[projectId];
        require(p.active, "Not active");
        require(p.owner == msg.sender, "Not owner");
        require(bytes(name).length > 0, "Name required");
        require(bytes(repoUrl).length > 0, "Repo URL required");

        p.name        = name;
        p.repoUrl     = repoUrl;
        p.description = description;

        if (msg.value > fee) payable(msg.sender).transfer(msg.value - fee);
        emit ProjectUpdated(projectId);
    }

    function getProject(uint256 projectId)
        external
        view
        returns (
            address owner,
            string memory name,
            string memory repoUrl,
            string memory description,
            uint256 registeredAt,
            bool    active
        )
    {
        Project storage p = _projects[projectId];
        require(p.registeredAt != 0, "No such project");
        return (
            p.owner,
            p.name,
            p.repoUrl,
            p.description,
            p.registeredAt,
            p.active
        );
    }
}
