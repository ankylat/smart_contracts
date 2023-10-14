// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyDementor is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _notebookIdCounter;

    struct DementorPage {
        string promptCID;
        string userWritingCID;
        uint256 timestamp;
    }

    struct DementorNotebook {
        string introCID;
        DementorPage[] pages;
        uint256 currentPage;
    }

    mapping(uint256 => DementorNotebook) public dementorNotebooks;
    IAnkyAirdrop public ankyAirdrop;

    event DementorNotebookCreated(uint256 indexed tokenId, address indexed owner);

    modifier onlyAnkyHolder() {
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "You must own an Anky");
        _;
    }

    constructor(address _ankyAirdrop) ERC721("AnkyDementor", "AD") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
    }

    function createAnkyDementorNotebook(string memory introCID) external onlyAnkyHolder {
        uint256 tokenId = _notebookIdCounter.current() + 1;
        _notebookIdCounter.increment();

        DementorNotebook storage notebook = dementorNotebooks[tokenId];
        notebook.introCID = introCID;
        notebook.currentPage = 1;

        _mint(msg.sender, tokenId);

        emit DementorNotebookCreated(tokenId, msg.sender);
    }

    function writeDementorPage(uint256 dementorNotebookId, string memory userWritingCID, string memory nextPromptCID) external onlyAnkyHolder {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(ownerOf(dementorNotebookId) == usersAnkyAddress, "Not the owner of this dementor notebook");

        DementorNotebook storage notebook = dementorNotebooks[dementorNotebookId];
        DementorPage storage currentPage = notebook.pages[notebook.currentPage];
        currentPage.userWritingCID = userWritingCID;
        currentPage.timestamp = block.timestamp;

        DementorPage storage nextPage = notebook.pages.push();
        nextPage.promptCID = nextPromptCID;

        notebook.currentPage++;
    }

    function getCurrentPage(uint256 dementorNotebookId) external view returns (DementorPage memory) {
        require(_exists(dementorNotebookId), "Invalid tokenId");
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(ownerOf(dementorNotebookId) == usersAnkyAddress, "Not the owner of this dementor notebook");

        DementorNotebook storage notebook = dementorNotebooks[dementorNotebookId];
        return notebook.pages[notebook.currentPage];
    }

    function doesUserOwnAnkyDementor() external view returns (bool) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesn't exist");
        return balanceOf(usersAnkyAddress) > 0;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
