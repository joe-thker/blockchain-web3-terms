// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract SimpleGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorTimelockControl
{
    constructor(IVotes token, TimelockController timelock)
        Governor("SimpleGovernor")
        GovernorSettings(/*delay*/1, /*period*/45818, /*threshold*/0)
        GovernorVotes(token)
        GovernorTimelockControl(timelock)
    {}

    /* ── Quorum: 1 % of total supply ── */
    function quorum(uint256) public view override returns (uint256) {
        return token.getPastTotalSupply(block.number - 1) / 100;
    }

    /* ── required overrides ── */
    function votingDelay()
        public view override(Governor, GovernorSettings) returns (uint256)
    { return super.votingDelay(); }

    function votingPeriod()
        public view override(Governor, GovernorSettings) returns (uint256)
    { return super.votingPeriod(); }

    function proposalThreshold()
        public view override(Governor, GovernorSettings) returns (uint256)
    { return super.proposalThreshold(); }

    /* Timelock routing */
    function state(uint256 id)
        public view override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    { return super.state(id); }

    function _queueOperations(
        uint256 id,
        address[] memory t,
        uint256[] memory v,
        bytes[] memory c,
        bytes32 h
    )
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint256)
    { return super._queueOperations(id, t, v, c, h); }

    function _executeOperations(
        uint256 id,
        address[] memory t,
        uint256[] memory v,
        bytes[] memory c,
        bytes32 h
    )
        internal
        override(Governor, GovernorTimelockControl)
    { super._executeOperations(id, t, v, c, h); }

    function proposalNeedsQueuing(uint256 id)
        public view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    { return super.proposalNeedsQueuing(id); }

    function _executor()
        internal view
        override(Governor, GovernorTimelockControl)
        returns (address)
    { return super._executor(); }

    function supportsInterface(bytes4 iid)
        public view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    { return super.supportsInterface(iid); }
}
