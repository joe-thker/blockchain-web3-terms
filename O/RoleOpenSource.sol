// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleOpenSource is AccessControl {
    bytes32 public constant PUBLISHER_ROLE = keccak256("PUBLISHER_ROLE");

    struct Project {
        address owner;
        string  name;
        string  repoUrl;
        string  description;
        uint256 registeredAt;
        bool    active;
    }

    uint256 private _nextId = 1;
    mapping(uint256 => Project) private _projects;
    mapping(address => uint256[]) private _ownerToProjects;

    event ProjectRegistered(uint256 indexed id, address indexed owner);
    event ProjectUpdated(uint256 indexed id);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PUBLISHER_ROLE, admin);
    }

    function grantPublisher(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(PUBLISHER_ROLE, account);
    }

    function revokePublisher(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(PUBLISHER_ROLE, account);
    }

    function registerProject(
        string calldata name,
        string calldata repoUrl,
        string calldata description
    ) external onlyRole(PUBLISHER_ROLE) returns (uint256 projectId) {
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

        emit ProjectRegistered(projectId, msg.sender);
    }

    function updateProject(
        uint256 projectId,
        string calldata name,
        string calldata repoUrl,
        string calldata description
    ) external onlyRole(PUBLISHER_ROLE) {
        Project storage p = _projects[projectId];
        require(p.active, "Not active");
        require(p.owner == msg.sender, "Not owner");

        p.name        = name;
        p.repoUrl     = repoUrl;
        p.description = description;
        emit ProjectUpdated(projectId);
    }
}
