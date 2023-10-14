// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyJournals is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    enum JournalType { Small, Medium, Large }

    struct JournalEntry {
        string cid; // pointer to content on Arweave
        uint256 timestamp; // timestamp of when it was written
        bool isPublic; // true if entry is public
    }

    struct Journal {
        JournalType journalType;
        uint8 pagesLeft;
        uint256 journalId;
        string metadataCID; // pointer to metadata on Arweave
        JournalEntry[] entries;
    }

    mapping(uint256 => Journal) public journals; // Mapping from token ID to Journal
    mapping(address => uint256[]) public userJournalIds; // Mapping from user address to list of their journal token IDs

    IAnkyAirdrop public ankyAirdrop;
    uint256 public smallJournalPrice;
    uint256 public mediumJournalPrice;
    uint256 public largeJournalPrice;

    event JournalAirdropped(uint256 indexed tokenId, address indexed recipient);
    event JournalMinted(uint256 indexed tokenId, address indexed owner);
    event PagesDepleted(uint256 indexed tokenId);

     modifier onlyAnkyHolder() {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");
        _;
    }

    modifier onlyAnkyOwner() {
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "Must own an Anky");
        _;
    }

    constructor(address _ankyAirdrop) ERC721("AnkyJournals", "AJ") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
        smallJournalPrice = 0.0001 ether;
        mediumJournalPrice = 0.0002 ether;
        largeJournalPrice = 0.0003 ether;
    }

    function airdropFirstJournal(address userAddress) external onlyOwner {
        // Check if the user already owns a journal
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(userAddress);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(balanceOf(usersAnkyAddress) == 0, "User already owns a journal");
        // Mint the journal (you can decide which type, I assume Small for this example)
        uint256 tokenId = _tokenIdCounter.current() + 1;
        _tokenIdCounter.increment();

        Journal storage journal = journals[tokenId];
        journal.journalType = JournalType.Small;
        journal.pagesLeft = 8;
        journal.journalId = tokenId;
        journal.metadataCID = "";

        userJournalIds[usersAnkyAddress].push(tokenId);

        _mint(usersAnkyAddress, tokenId);

        emit JournalAirdropped(tokenId, usersAnkyAddress);
    }

    function mintJournal(JournalType journalType) external payable onlyAnkyHolder {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");
        uint256 cost;
        uint8 pages;

        if (journalType == JournalType.Small) {
            pages = 8;
            cost = smallJournalPrice;
        } else if (journalType == JournalType.Medium) {
            pages = 24;
            cost = mediumJournalPrice;
        } else {
            pages = 96;
            cost = largeJournalPrice;
        }

        require(msg.value == cost, "Incorrect Ether sent");

        uint256 tokenId = totalSupply() + 1;

        Journal storage journal = journals[tokenId];
        journal.journalType = journalType;
        journal.pagesLeft = pages;
        journal.journalId = tokenId;
        journal.metadataCID = "";

        userJournalIds[usersAnkyAddress].push(tokenId);

        _mint(usersAnkyAddress, tokenId);

        uint256 userShare = (msg.value * 70) / 100;
        payable(msg.sender).transfer(userShare);

        emit JournalMinted(tokenId, usersAnkyAddress);
    }

    function writeJournalPage(uint256 journalId, string memory cid, bool isPublic) external onlyAnkyOwner {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(ownerOf(journalId) == usersAnkyAddress, "Not the owner of this journal");
        Journal storage journal = journals[journalId];
        require(journal.pagesLeft > 0, "No pages left in this journal");

        JournalEntry storage newEntry = journal.entries.push();
        newEntry.cid = cid;
        newEntry.timestamp = block.timestamp;
        newEntry.isPublic = isPublic;

        journal.pagesLeft--;

        if(journal.pagesLeft == 0) {
            emit PagesDepleted(journalId);
        }

        if (true) {
            ankyAirdrop.registerWriting(usersAnkyAddress, "journal", cid);
        }
    }

    function getJournal(uint256 tokenId) external view returns (Journal memory) {
        require(_exists(tokenId), "Invalid tokenId");
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(ownerOf(tokenId) == usersAnkyAddress, "Not the owner of this journal");
        return journals[tokenId];
    }

    function getUserJournals() external view returns (uint256[] memory) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        return userJournalIds[usersAnkyAddress];
    }

    function setJournalPrices(uint256 _smallPrice, uint256 _mediumPrice, uint256 _largePrice) external onlyOwner {
        smallJournalPrice = _smallPrice;
        mediumJournalPrice = _mediumPrice;
        largeJournalPrice = _largePrice;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
