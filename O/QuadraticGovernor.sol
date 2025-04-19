// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

/* ── Token (same as before) ── */
contract QGovToken is ERC20, ERC20Permit, ERC20Votes {
    constructor(uint256 supply)
        ERC20("QuadraticGovToken", "QGT")
        ERC20Permit("QuadraticGovToken")
    { _mint(msg.sender, supply); }

    function _update(address f, address t, uint256 a)
        internal override(ERC20, ERC20Votes)
    { super._update(f,t,a); }
}

/* ── Governor with quadratic counting ── */
contract QuadraticGovernor is
    Governor,
    GovernorTimelockControl
{
    constructor(IVotes token, TimelockController tl)
        Governor("QuadraticGovernor")
        GovernorTimelockControl(tl)
    { _token = token; }

    IVotes private immutable _token;

    /* ── voting configuration ── */
    function votingDelay() public pure override returns (uint256) { return 1; }
    function votingPeriod() public pure override returns (uint256){ return 45818; }
    function proposalThreshold() public pure override returns (uint256){ return 0; }
    function quorum(uint256) public pure override returns (uint256){ return 0; }

    /* ── quadratic counting override ── */
    function _getVotes(
        address acct, uint256 blk, bytes memory /*params*/
    ) internal view override returns (uint256) {
        uint256 raw = _token.getPastVotes(acct, blk);
        return _sqrt(raw);
    }
    function _sqrt(uint256 x) private pure returns (uint256 y){
        if (x==0) return 0;
        uint256 z=(x+1)/2; y=x;
        while(z<y){y=z; z=(x/z+z)/2;}
    }

    /* ── timelock glue ── */
    function state(uint256 pid)
        public view override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    { return super.state(pid); }

    function _execute(
        uint256 pid,address[] memory t,uint256[] memory v,
        bytes[] memory c,bytes32 h
    ) internal override(Governor,GovernorTimelockControl)
    { super._execute(pid,t,v,c,h); }

    function _cancel(
        address[] memory t,uint256[] memory v,bytes[] memory c,bytes32 h
    ) internal override(Governor,GovernorTimelockControl)
        returns (uint256)
    { return super._cancel(t,v,c,h); }

    function _executor()
        internal view override(Governor,GovernorTimelockControl)
        returns (address)
    { return super._executor(); }

    function supportsInterface(bytes4 id)
        public view override(Governor,GovernorTimelockControl)
        returns (bool)
    { return super.supportsInterface(id); }
}
