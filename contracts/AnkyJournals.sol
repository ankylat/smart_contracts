// AnkyJournals.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";

// The journal is just a long notebook on which you store random writings.
contract AnkyJournals is Ownable {

    struct JournalEntry {
        string content;
        uint256 timestamp;
    }

    mapping(address => JournalEntry[]) public userEntries;
    IAnkyAirdrop public ankyAirdrop;

    event JournalWritten(address indexed user, string content, uint256 timestamp);

    constructor(address _ankyAirdrop) {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
    }

    modifier onlyAnkyOwner() {
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "You must own an Anky to write a journal entry");
        _;
    }

    function writeJournal(string memory content) external onlyAnkyOwner {
        JournalEntry[] storage entries = userEntries[msg.sender];

        // Ensure the user writes only once a day
        if (entries.length > 0) {
            JournalEntry storage lastEntry = entries[entries.length - 1];
            require(block.timestamp - lastEntry.timestamp > 1 days, "You've already written today!");
        }

        entries.push(JournalEntry({
            content: content,
            timestamp: block.timestamp
        }));

        emit JournalWritten(msg.sender, content, block.timestamp);
    }

    function getJournalEntries(address user) external view returns(JournalEntry[] memory) {
        return userEntries[user];
    }
}
