// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*  ─────────────────────────────────────────────────────────────
    IMPORTS
    ───────────────────────────────────────────────────────────── */
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

/*  ─────────────────────────────────────────────────────────────
    GOVERNANCE TOKEN
    ───────────────────────────────────────────────────────────── */
contract GovernanceToken is ERC20, ERC20Permit, ERC20Votes {
    constructor(uint256 initialSupply)
        ERC20("GovernanceToken", "GOV")
        ERC20Permit("GovernanceToken")
    {
        _mint(msg.sender, initialSupply);
    }

    /* OpenZeppelin v5.x requires overriding **_update** (not _afterTokenTransfer / _mint / _burn). */
    function _update(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, amount);
    }
}

/*  ─────────────────────────────────────────────────────────────
    TIMELOCK
    ───────────────────────────────────────────────────────────── */
contract Timelock is TimelockController {
    constructor(
        uint256   minDelay,            // e.g. 2 days
        address[] memory proposers,    // governor address array
        address[] memory executors     // executors (address(0) => anyone)
    ) TimelockController(minDelay, proposers, executors) {}
}

/*  ─────────────────────────────────────────────────────────────
    GOVERNOR
    ───────────────────────────────────────────────────────────── */
contract MyGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorTimelockControl
{
    constructor(IVotes token, TimelockController timelock)
        Governor("MyGovernor")
        GovernorSettings(
            /* votingDelay   */ 1,        // 1 block
            /* votingPeriod  */ 45818,    // ~1 week (13 s blocks)
            /* proposalThreshold */ 0
        )
        GovernorVotes(token)
        GovernorTimelockControl(timelock)
    {}

    /* ──────────── Quorum: fixed 100 tokens ──────────── */
    function quorum(uint256) public pure override returns (uint256) {
        return 100 * 10 ** 18;
    }

    /* ──────────── Overrides required by Solidity ─────── */
    function votingDelay()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    { return super.votingDelay(); }

    function votingPeriod()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    { return super.votingPeriod(); }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    { return super.proposalThreshold(); }

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    { return super.state(proposalId); }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    )
        public
        override(Governor)
        returns (uint256)
    { return super.propose(targets, values, calldatas, description); }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        internal
        override(Governor, GovernorTimelockControl)
    { super._execute(proposalId, targets, values, calldatas, descriptionHash); }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint256)
    { return super._cancel(targets, values, calldatas, descriptionHash); }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    { return super._executor(); }

    /* supportsInterface glue */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    { return super.supportsInterface(interfaceId); }
}
