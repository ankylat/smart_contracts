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
        mapping(uint256 => UserPageContent) userPages;
        bool isVirgin;
    }

    IAnkyAirdrop public ankyAirdrop;
    AnkyTemplates public ankyTemplates;
    Counters.Counter private _notebookIds;

    // First mapping maps a notebookId to a pageNumber and then to the PageContent.
    mapping(uint256 => mapping(uint256 => UserPageContent)) public notebookPages;
    // This one maps the id of the notebok to the particular notebook itself.
    mapping(uint256 => NotebookInstance) public notebookInstances;
     // This mapping is for storing all the notebooks that a particular anky tba owns.
    mapping(address => uint256[]) public ankyTbaToOwnedNotebooks;
    // Track the last page written by the user for each notebook
    mapping(uint256 => uint256) public notebookLastPageWritten;


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
        require(amount > 0 && amount <= 5, "You can mint between 1 to 5 notebooks");

        // This line I don't properly understand.
        AnkyTemplates.NotebookTemplate memory notebookTemplate = ankyTemplates.getTemplate(templateId);
        // Ensure that the template was created by an account and exists.
        require(notebookTemplate.creator != address(0), "Invalid templateId");

                // Check supply constraints
        uint256 currentSupply = ankyTemplates.getTemplateSupply(templateId);
        require(currentSupply >= amount, "Insufficient supply");

        uint256 totalPrice = notebookTemplate.price * amount;
        require(msg.value >= totalPrice, "Insufficient Ether sent");

        for (uint256 i = 0; i < amount; i++) {
            uint256 newNotebookId = _notebookIds.current();

            notebookInstances[newNotebookId].templateId = templateId;
            notebookInstances[newNotebookId].isVirgin = true;

            _mint(tbaAddress, newNotebookId);
            ankyTemplates.addInstanceToTemplate(templateId, newNotebookId);
            ankyTbaToOwnedNotebooks[tbaAddress].push(newNotebookId);

            emit NotebookMinted(newNotebookId, tbaAddress, templateId);
            _notebookIds.increment();
        }

        uint256 creatorShare = (totalPrice * 10) / 100;
        uint256 userShare = (totalPrice * 70) / 100;

        payable(notebookTemplate.creator).transfer(creatorShare);
        payable(to).transfer(userShare);
    }


   function writePage(uint256 notebookId, uint256 pageNumber, string memory arweaveCID) external {
        require(ownerOf(notebookId) == ankyAirdrop.getUsersAnkyAddress(msg.sender), "Only the owner of the anky that stores this notebook can write");

        // Ensure the page hasn't been written before
        require(bytes(notebookPages[notebookId][pageNumber].arweaveCID).length == 0, "Page already written");
        uint256 lastPageWritten = notebookLastPageWritten[notebookId];
        uint256 nextPageToWrite = lastPageWritten + 1;

        // Retrieve the prompt for the next page
        string memory prompt = ankyTemplates.getTemplatePrompt(notebookInstances[notebookId].templateId, nextPageToWrite);

        require(bytes(prompt).length > 0, "No more pages available to write");
        require(bytes(notebookPages[notebookId][nextPageToWrite].arweaveCID).length == 0, "Page already written");


        notebookPages[notebookId][pageNumber] = UserPageContent({
            arweaveCID: arweaveCID,
            timestamp: block.timestamp
        });

        NotebookInstance storage notebookInstance = notebookInstances[notebookId];
        if(notebookInstance.isVirgin) {
            notebookInstance.isVirgin = false;
        }

        emit PageWritten(notebookId, pageNumber, prompt, arweaveCID, block.timestamp);
    }

      function getPageContent(uint256 notebookId, uint256 pageNumber) external view returns(UserPageContent memory) {
        return notebookPages[notebookId][pageNumber];
    }

    function getFullNotebook(uint256 notebookId) external view returns(uint256 templateId, UserPageContent[] memory pages) {
        NotebookInstance storage instance = notebookInstances[notebookId];
        templateId = instance.templateId;

        uint256 numPages = ankyTemplates.getNumPagesOfTemplate(templateId);
        pages = new UserPageContent[](numPages);
        for (uint256 i = 0; i < numPages; i++) {
            pages[i] = notebookPages[notebookId][i];
        }
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
}
