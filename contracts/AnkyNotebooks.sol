// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";
import "./AnkyTemplates.sol";

contract AnkyNotebooks is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    struct UserPageContent {
        string arweaveCID;      // URL pointing to the user's answer on Arweave
        uint256 timestamp;      // The time when the content was added
    }

    struct NotebookInstance {
        uint256 templateId;
        UserPageContent[] userPages;
        bool isVirgin;
    }

    IAnkyAirdrop public ankyAirdrop;
    AnkyTemplates public ankyTemplates;
    Counters.Counter private _notebookIds;

    // This one maps the id of the notebok to the particular notebook itself.
    mapping(uint256 => NotebookInstance) public notebookInstances;
     // This mapping is for storing all the notebooks that a particular anky tba owns.
    mapping(address => uint256[]) public ankyTbaToOwnedNotebooks;
    // Track the last page written by the user for each notebook
    mapping(uint256 => uint256) public notebookLastPageWritten;

    event FundsTransferred(address recipient, uint256 amount);
    event NotebookMinted(uint256 indexed instanceId, address indexed owner, uint256 indexed templateId);

    constructor(address _ankyAirdrop, address _ankyTemplates) ERC721("Anky Notebooks", "ANKYNB") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
        ankyTemplates = AnkyTemplates(_ankyTemplates);
    }

   function mintNotebook(address to, uint256 templateId, uint256 amount) external payable {
        // Does the user own an anky?
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "Address needs to own an Anky to mint a notebook");
        // Check which is the address of the anky that the user owns
        address tbaAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(tbaAddress != address(0), "Invalid Anky address");
        require(amount == 1, "You can mint only one notebook at a time");

        // This line I don't properly understand.
        AnkyTemplates.NotebookTemplate memory notebookTemplate = ankyTemplates.getTemplate(templateId);
        // Ensure that the template was created by an account and exists.
        require(notebookTemplate.creator != address(0), "Invalid templateId");

                // Check supply constraints
        uint256 currentSupply = notebookTemplate.supply;
        require(currentSupply >= amount, "Insufficient supply");

        uint256 totalPrice = notebookTemplate.price * amount;
        require(msg.value >= totalPrice, "Insufficient Ether sent");
        uint256 currentNotebookId = _notebookIds.current();

        notebookInstances[currentNotebookId].templateId = templateId;
        notebookInstances[currentNotebookId].isVirgin = true;

        _mint(tbaAddress, currentNotebookId);
        ankyTemplates.addInstanceToTemplate(templateId, currentNotebookId);
        ankyTbaToOwnedNotebooks[tbaAddress].push(currentNotebookId);

        emit NotebookMinted(currentNotebookId, tbaAddress, templateId);
        currentNotebookId++;

        uint256 creatorShare = (totalPrice * 10) / 100;
        uint256 userShare = (totalPrice * 70) / 100;

        // Transfer back part of the money to the creator of the template and to the wallet that is minting.
        payable(notebookTemplate.creator).transfer(creatorShare);
        emit FundsTransferred(notebookTemplate.creator, creatorShare);

        payable(to).transfer(userShare);
        emit FundsTransferred(to, userShare);
    }

    modifier onlyNotebookOwner(uint256 notebookId) {
        require(ownerOf(notebookId) == ankyAirdrop.getUsersAnkyAddress(msg.sender), "Only the owner of the anky that stores this notebook can perform this action");
        _;
    }

    function writePage(uint256 notebookId, uint256 pageNumber, string memory arweaveCID) external onlyNotebookOwner(notebookId) {
        uint256 lastPageWritten = notebookLastPageWritten[notebookId];
        require(pageNumber == lastPageWritten + 1, "Pages must be written in sequence");

        NotebookInstance storage notebookInstance = notebookInstances[notebookId];

        // Ensure the page hasn't been written before
        require(notebookInstance.userPages.length < pageNumber, "Page already written");

        string memory prompt = ankyTemplates.getTemplatePrompt(notebookInstance.templateId, pageNumber);
        require(bytes(prompt).length > 0, "No more pages available to write");

        if(notebookInstance.isVirgin) {
            notebookInstance.isVirgin = false;
        }

        notebookInstance.userPages.push(UserPageContent({
            arweaveCID: arweaveCID,
            timestamp: block.timestamp
        }));

        emit PageWritten(notebookId, pageNumber, prompt, arweaveCID, block.timestamp);
        notebookLastPageWritten[notebookId] = pageNumber;
    }


    function getPageContent(uint256 notebookId, uint256 pageNumber) external view returns(UserPageContent memory) {
        return notebookInstances[notebookId].userPages[pageNumber];
    }

    function getFullNotebook(uint256 notebookId) external view returns(UserPageContent[] memory pages) {
        NotebookInstance storage instance = notebookInstances[notebookId];
        return (instance.userPages);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 tokenBatch) internal override {
        super._beforeTokenTransfer(from, to, tokenId, tokenBatch);
        // Check if it's a transfer action (not mint or burn)
        if(from != address(0) && to != address(0)) {
            require(notebookInstances[tokenId].isVirgin, "Notebook has been written and cannot be transferred directly");
        }
    }


    function getOwnedNotebooks(address user) external view returns(uint256[] memory) {
        return ankyTbaToOwnedNotebooks[user];
    }

    event PageWritten(uint256 indexed notebookId, uint256 indexed pageNumber, string prompt, string arweaveURL, uint256 timestamp);


    function isVirgin(uint256 notebookId) external view returns(bool) {
        return notebookInstances[notebookId].isVirgin;
    }

    function getUserVirginNotebooks(address user) external view returns (uint256[] memory) {
        uint256[] memory allNotebooks = ankyTbaToOwnedNotebooks[user];
        uint256 count = 0;
        for(uint256 i = 0; i < allNotebooks.length; i++) {
            if(notebookInstances[allNotebooks[i]].isVirgin) {
                count++;
            }
        }

        uint256[] memory virginNotebooks = new uint256[](count);
        uint256 index = 0;
        for(uint256 i = 0; i < allNotebooks.length; i++) {
            if(notebookInstances[allNotebooks[i]].isVirgin) {
                virginNotebooks[index] = allNotebooks[i];
                index++;
            }
        }
        return virginNotebooks;
    }
}
