// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title OpenSourceRegistry
 * @notice A simple on‑chain registry for open‑source projects:
 *         • Anyone can register a project with metadata (name, repo URL, description).  
 *         • Project owners can update their metadata and manage contributors.  
 *         • Registry owner can pause all registrations/updates in an emergency.
 *
 * FIX: Added `constructor() Ownable(msg.sender)` so the
 *      OpenZeppelin Ownable base constructor receives its
 *      required `initialOwner` argument, removing the compilation error.
 */
contract OpenSourceRegistry is Ownable, Pausable {
    struct Project {
        address owner;
        string  name;
        string  repoUrl;
        string  description;
        uint256 registeredAt;
        bool    active;
    }

    uint256 private _nextProjectId = 1;
    mapping(uint256 => Project) private _projects;
    mapping(address => uint256[]) private _ownerToProjects;
    mapping(uint256 => address[]) private _projectContributors;
    mapping(uint256 => mapping(address => bool)) private _isContributor;

    /* ---------------- constructor (FIX) ---------------- */
    constructor() Ownable(msg.sender) {}

    /* Events */
    event ProjectRegistered(uint256 indexed projectId, address indexed owner);
    event ProjectUpdated(uint256 indexed projectId);
    event ContributorAdded(uint256 indexed projectId, address indexed contributor);
    event ContributorRemoved(uint256 indexed projectId, address indexed contributor);
    event ProjectDeactivated(uint256 indexed projectId);

    /* Modifiers */
    modifier onlyProjectOwner(uint256 projectId) {
        require(_projects[projectId].owner == msg.sender, "Not project owner");
        _;
    }

    modifier projectExists(uint256 projectId) {
        require(_projects[projectId].active, "Project not active");
        _;
    }

    /// @notice Register a new open‑source project.
    function registerProject(
        string calldata name,
        string calldata repoUrl,
        string calldata description
    )
        external
        whenNotPaused
        returns (uint256 projectId)
    {
        require(bytes(name).length > 0, "Name required");
        require(bytes(repoUrl).length > 0, "Repo URL required");

        projectId = _nextProjectId++;
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

    /// @notice Update metadata for your project.
    function updateProject(
        uint256 projectId,
        string calldata name,
        string calldata repoUrl,
        string calldata description
    )
        external
        whenNotPaused
        projectExists(projectId)
        onlyProjectOwner(projectId)
    {
        require(bytes(name).length > 0, "Name required");
        require(bytes(repoUrl).length > 0, "Repo URL required");

        Project storage p = _projects[projectId];
        p.name = name;
        p.repoUrl = repoUrl;
        p.description = description;

        emit ProjectUpdated(projectId);
    }

    /// @notice Add a contributor to your project.
    function addContributor(uint256 projectId, address contributor)
        external
        whenNotPaused
        projectExists(projectId)
        onlyProjectOwner(projectId)
    {
        require(contributor != address(0), "Zero address");
        require(!_isContributor[projectId][contributor], "Already contributor");

        _isContributor[projectId][contributor] = true;
        _projectContributors[projectId].push(contributor);

        emit ContributorAdded(projectId, contributor);
    }

    /// @notice Remove a contributor from your project.
    function removeContributor(uint256 projectId, address contributor)
        external
        whenNotPaused
        projectExists(projectId)
        onlyProjectOwner(projectId)
    {
        require(_isContributor[projectId][contributor], "Not a contributor");

        _isContributor[projectId][contributor] = false;
        address[] storage arr = _projectContributors[projectId];
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == contributor) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                break;
            }
        }

        emit ContributorRemoved(projectId, contributor);
    }

    /// @notice Deactivate a project (no further updates).
    function deactivateProject(uint256 projectId)
        external
        projectExists(projectId)
        onlyProjectOwner(projectId)
    {
        _projects[projectId].active = false;
        emit ProjectDeactivated(projectId);
    }

    /// @notice Pause the registry (owner only).
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the registry (owner only).
    function unpause() external onlyOwner {
        _unpause();
    }

    /* ========== View Functions ========== */

    function getProject(uint256 projectId)
        external
        view
        returns (
            address owner,
            string memory name,
            string memory repoUrl,
            string memory description,
            uint256 registeredAt,
            bool active
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

    function getContributors(uint256 projectId)
        external
        view
        returns (address[] memory)
    {
        return _projectContributors[projectId];
    }
}
