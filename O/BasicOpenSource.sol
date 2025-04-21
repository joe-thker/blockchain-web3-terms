// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BasicOpenSource {
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
    event ProjectDeactivated(uint256 indexed id);

    /// Register a new project
    function registerProject(
        string calldata name,
        string calldata repoUrl,
        string calldata description
    ) external returns (uint256 projectId) {
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

    /// Update metadata (only by owner)
    function updateProject(
        uint256 projectId,
        string calldata name,
        string calldata repoUrl,
        string calldata description
    ) external {
        Project storage p = _projects[projectId];
        require(p.active, "Not active");
        require(p.owner == msg.sender, "Not owner");
        require(bytes(name).length > 0, "Name required");
        require(bytes(repoUrl).length > 0, "Repo URL required");

        p.name        = name;
        p.repoUrl     = repoUrl;
        p.description = description;
        emit ProjectUpdated(projectId);
    }

    /// Deactivate project (only by owner)
    function deactivateProject(uint256 projectId) external {
        Project storage p = _projects[projectId];
        require(p.active, "Not active");
        require(p.owner == msg.sender, "Not owner");
        p.active = false;
        emit ProjectDeactivated(projectId);
    }

    /// View helpers
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

    function getProjectsByOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        return _ownerToProjects[owner];
    }
}
