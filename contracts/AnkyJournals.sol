// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyJournals is ERC721, Ownable {

    struct Journal {
        uint32 journalId;
        string metadataCID; // name
        string pagesPasswordsCID;
    }

    mapping(uint32 => Journal) public journals; // Mapping from token ID to Journal
    mapping(address => uint32[]) public userJournalIds; // Mapping from user address to list of their journal token IDs

    IAnkyAirdrop public ankyAirdrop;
    uint256 public smallJournalPrice;
    uint256 public mediumJournalPrice;
    uint256 public largeJournalPrice;

    event JournalAirdropped(uint32 indexed journalId, address indexed recipient);
    event JournalMinted(uint32 indexed journalId, address indexed owner);
    event PagesDepleted(uint32 indexed journalId);

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
        uint32 newJournalId = uint32(bytes4(keccak256(abi.encodePacked(msg.sender, uint256(123456789)))));

        Journal storage journal = journals[newJournalId];
        journal.journalType = JournalType.Small;
        journal.pagesLeft = 8;
        journal.journalId = newJournalId;
        journal.metadataCID = "";

        userJournalIds[usersAnkyAddress].push(newJournalId);

        _mint(usersAnkyAddress, newJournalId);

        emit JournalAirdropped(newJournalId, usersAnkyAddress);
    }

    function mintJournal(JournalType journalType, uint256 randomUID) external payable onlyAnkyHolder {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");
        uint32 newJournalId = uint32(bytes4(keccak256(abi.encodePacked(msg.sender, randomUID))));
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

        Journal storage journal = journals[newJournalId];
        journal.journalType = journalType;
        journal.pagesLeft = pages;
        journal.journalId = newJournalId;
        journal.metadataCID = "";

        userJournalIds[usersAnkyAddress].push(newJournalId);

        _mint(usersAnkyAddress, newJournalId);

        uint256 userShare = (msg.value * 70) / 100;
        payable(msg.sender).transfer(userShare);

        emit JournalMinted(newJournalId, usersAnkyAddress);
    }

    function writeJournalPage(uint32 journalId, string memory cid, bool isPublic) external onlyAnkyOwner {
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

    function getJournal(uint32 journalId) external view returns (Journal memory) {
        require(_exists(journalId), "Invalid tokenId");
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(ownerOf(journalId) == usersAnkyAddress, "Not the owner of this journal");
        return journals[journalId];
    }

    function getUserJournals() external view returns (uint32[] memory) {
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
