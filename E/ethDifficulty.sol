// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DifficultyLogger {
    struct DifficultyEntry {
        uint256 blockNumber;
        uint256 difficulty;
    }

    mapping(address => DifficultyEntry[]) public userDifficultyHistory;

    event DifficultyLogged(address indexed user, uint256 blockNumber, uint256 difficulty);

    function logMyDifficulty() external {
        uint256 currentDifficulty = block.difficulty; // In PoS, this is now randomness (prevrandao)
        userDifficultyHistory[msg.sender].push(DifficultyEntry({
            blockNumber: block.number,
            difficulty: currentDifficulty
        }));
        emit DifficultyLogged(msg.sender, block.number, currentDifficulty);
    }

    function getMyHistoryLength() external view returns (uint256) {
        return userDifficultyHistory[msg.sender].length;
    }

    function getMyDifficultyAt(uint256 index) external view returns (uint256 blockNumber, uint256 difficulty) {
        require(index < userDifficultyHistory[msg.sender].length, "Index out of bounds");
        DifficultyEntry memory entry = userDifficultyHistory[msg.sender][index];
        return (entry.blockNumber, entry.difficulty);
    }
}
