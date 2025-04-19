// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";

/**
 * @title NFTGovernor
 * @notice Governor that uses GovernanceNFT voting power.
 */
contract NFTGovernor is
    Governor,
    GovernorCountingSimple,
    GovernorVotes
{
    constructor(IVotes nftToken)
        Governor("NFTGovernor")
        GovernorVotes(nftToken)
    {}

    /* ─────────── Governance params ─────────── */
    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 block
    }

    function votingPeriod() public pure override returns (uint256) {
        return 40320; // ~1 week (13 s blocks)
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 0; // no threshold
    }

    /* Simple quorum: at least 1 NFT must vote “for” */
    function quorum(uint256) public pure override returns (uint256) {
        return 1;
    }

    /* supportsInterface passthrough */
    function supportsInterface(bytes4 iid)
        public
        view
        override(Governor)
        returns (bool)
    {
        return super.supportsInterface(iid);
    }
}
