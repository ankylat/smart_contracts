// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyJournals is ERC721, Ownable {
    uint256 private _journalIds;

    uint256 public journalPrice;

    struct Journal {
        uint256 journalId;
        string title;
    }

    mapping(uint256 => Journal) public journals; // Mapping from token ID to Journal
    mapping(address => uint256[]) public userJournalIds; // Mapping from user address to list of their journal token IDs

    IAnkyAirdrop public ankyAirdrop;

    event JournalCreated(uint256 indexed journalId, address indexed owner, string indexed title);


    modifier onlyAnkyOwner() {
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "Must own an Anky");
        _;
    }

    constructor(address _ankyAirdrop) ERC721("AnkyJournals", "AJ") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
        journalPrice = 0.0001 ether;
        _transferOwnership(_ankyAirdrop);
    }

    function mintJournal(string memory journalTitle) external onlyAnkyOwner {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);

        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        uint256 newJournalId = ++_journalIds;

        Journal storage journal = journals[newJournalId];
        journal.journalId = newJournalId;
        journal.title = journalTitle;

        _mint(usersAnkyAddress, newJournalId);
        userJournalIds[usersAnkyAddress].push(newJournalId);

        emit JournalCreated(newJournalId, usersAnkyAddress, journalTitle);
    }


    function getJournal(uint256 journalId) external view returns (Journal memory) {
        require(ERC721._exists(journalId), "Invalid tokenId");
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(ownerOf(journalId) == usersAnkyAddress, "Not the owner of this journal");
        return journals[journalId];
    }

    function getUserJournals() external view returns (uint256[] memory) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        return userJournalIds[usersAnkyAddress];
    }

    function setJournalPrice(uint256 _newJournalPrice) external onlyOwner {
        journalPrice = _newJournalPrice;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
