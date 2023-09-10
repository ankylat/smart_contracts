// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";
import "./AnkyTemplates.sol";

/*
The AnkyNotebooks smart contract is responsible for minting and managing individual notebook instances based on the templates from the AnkyTemplates contract. As an ERC721 token, every notebook instance is unique, having an associated template ID and a status to determine if any writing has occurred. The contract also provides functionalities for users to write content on notebook pages and to check the content of any written page. For every minted notebook, an event is emitted, and the associated costs are shared with the creator. The contract collaborates with the AnkyAirdrop contract to ensure that only valid Anky owners can mint notebooks and write on them.
 */

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
        require(notebookTemplate.supply >= amount, "Insufficient supply");
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


   function writePage(uint256 notebookId, uint256 pageNumber, string memory prompt, string memory arweaveCID) external {
        // THE PROBLEM HERE IS WHAT HAPPENS WHEN THE NOTEBOOK WAS TRANSFERRED TO ANOTHER ADDRESS BECAUSE IT WAS SOLD. THERE NEEDS TO BE AN UPDATE OF THE FUNCTION THAT STORES THE INFORMATION AS OF WHICH IS THE ADDRESS OF THE ANKY THAT OWNS THE ANKY THAT IS HOLDING THE NOTEBOOK THAT IS GOING TO BE WRITTEN, AND HOW DOES THAT AFFECT WHAT IS DONE IN THIS FUNCTION.

        // THERE ALSO NEEDS TO BE A CHECK OF WHAT IS THE PAGE THAT COMES NOW. HOW DOES THE SYSTME KNOW WHAT IS THE PAGE THAT COMES?

        // HOW DO I RETRIEVE THE NEXT PAGE THAT NEEDS TO BE WRITTEN? THERE NEEDS TO BE A FUNCTION THAT CALLS THE PARTICULAR NOTEBOOK INSTANCE AND TELLS WHICH IS THE NEXT PROMPT THAT NEEDS TO BE ANSWERED. HOW WILL WE MAKE SURE THIS IS THE CASE? THAT IS THE CHALLENGE HERE.
        require(ownerOf(notebookId) == ankyAirdrop.getUsersAnkyAddress(msg.sender), "Only the owner of the anky that stores this notebook can write");

        // Ensure the page hasn't been written before
        require(bytes(notebookPages[notebookId][pageNumber].arweaveCID).length == 0, "Page already written");

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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if(from != address(0) && to != address(0)) { // not minting or burning
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
