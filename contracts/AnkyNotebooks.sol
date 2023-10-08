// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";
import "./AnkyTemplates.sol";

contract AnkyNotebooks is ERC1155, Ownable {
    using Counters for Counters.Counter;

    struct NotebookInstance {
        uint256 templateId;
        UserPageContent[] userPages;
        bool isVirgin;
    }

    struct UserPageContent {
        string cid;      // URL pointing to the user's answer on Arweave
        uint256 timestamp;      // The time when the content was added
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
    mapping(address => uint256[]) public ankyTbaToOwnedVirginNotebooks;
    mapping(address => mapping(uint256 => bool)) public hasWrittenInInstance;

    uint256 public constant MAX_NOTEBOOKS_PER_ADDRESS = 5;


    event FundsTransferred(address recipient, uint256 amount);
    event NotebookMinted(uint256 indexed instanceId, address indexed owner, uint256 indexed templateId);
    event PageWritten(uint256 indexed notebookId, uint256 indexed pageNumber, string arweaveURL, uint256 timestamp);

    constructor(address _ankyAirdrop, address _ankyTemplates) ERC1155("https://api.anky.lat/notebooksFromTemplates/{id}.json") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
        ankyTemplates = AnkyTemplates(_ankyTemplates);
    }

   function mintNotebook(address to, uint256 templateId, uint256 amount) external payable {
        require(ankyTbaToOwnedNotebooks[msg.sender].length + amount <= MAX_NOTEBOOKS_PER_ADDRESS, "There is a limit to the amount of notebooks that you can write to.");
        // Does the user own an anky?
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "Address needs to own an Anky to mint a notebook");
        // Check which is the address of the anky that the user owns
        address tbaAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(tbaAddress != address(0), "Invalid Anky address");

        AnkyTemplates.NotebookTemplate memory notebookTemplate = ankyTemplates.getTemplate(templateId);
        // Ensure that the template was created by an account and exists.
        require(notebookTemplate.creator != address(0), "Invalid templateId");

        // Check supply constraints
        uint256 currentSupply = notebookTemplate.supply;
        require(currentSupply >= amount, "Insufficient supply");

        uint256 totalPrice = notebookTemplate.price;
        require(msg.value >= totalPrice, "Insufficient Ether sent");

        uint256 currentNotebookId = _notebookIds.current();
        uint256 creatorShare = (totalPrice * 10) / 100;
        uint256 userShare = (totalPrice * 70) / 100;

        notebookInstances[currentNotebookId].templateId = templateId;
        notebookInstances[currentNotebookId].isVirgin = true;
        ankyTemplates.mintTemplateToken(msg.sender, templateId, amount, "");
        _notebookIds.increment();

        emit NotebookMinted(currentNotebookId, tbaAddress, templateId);

        // Transfer back part of the money to the creator of the template and to the wallet that is minting.
        payable(notebookTemplate.creator).transfer(creatorShare);
        emit FundsTransferred(notebookTemplate.creator, creatorShare);

        payable(to).transfer(userShare);
        emit FundsTransferred(to, userShare);

        emit NotebookMinted(currentNotebookId, tbaAddress, templateId);
    }


    modifier onlyNotebookOwner(uint256 notebookId) {
        require(balanceOf(ankyAirdrop.getUsersAnkyAddress(msg.sender), notebookId) > 0, "Only the owner of the anky that stores this notebook can perform this action");
            _;
    }

    function writeNotebookPage(uint256 uniqueNotebookId, string memory cid, uint256 pageNumber, bool isPublic) external {
        NotebookInstance storage notebookInstance = notebookInstances[uniqueNotebookId];
        uint256 templateId = notebookInstance.templateId;
        require(!hasWrittenInInstance[msg.sender][templateId], "You have already written in this notebook template instance.");
        require(balanceOf(msg.sender, uniqueNotebookId) == 1, "You don't own this notebook.");
        uint256 lastPageWritten = notebookLastPageWritten[uniqueNotebookId];
        require(pageNumber == lastPageWritten + 1, "Pages must be written in sequence");


        // Ensure the page hasn't been written before
        require(notebookInstance.userPages.length <= pageNumber, "Page already written or invalid page number");

        // Ensure the page is within the limit of the template's prompts
        AnkyTemplates.NotebookTemplate memory notebookTemplate = ankyTemplates.getTemplate(notebookInstance.templateId);
        require(pageNumber <= notebookTemplate.numberOfPrompts, "Page number exceeds the number of prompts for this notebook");

        if(notebookInstance.isVirgin) {
            notebookInstance.isVirgin = false;
            // If this notebook is written for the first time, remove it from virgin notebooks
            uint256[] storage virginNotebooks = ankyTbaToOwnedVirginNotebooks[msg.sender];
            for (uint256 i = 0; i < virginNotebooks.length; i++) {
                if (virginNotebooks[i] == uniqueNotebookId) {
                    virginNotebooks[i] = virginNotebooks[virginNotebooks.length - 1];
                    virginNotebooks.pop();
                    break;
                }
            }
        }

        notebookInstance.userPages.push(UserPageContent({
            cid: cid,
            timestamp: block.timestamp
        }));

        emit PageWritten(uniqueNotebookId, pageNumber, cid, block.timestamp);  // Updated emit based on event structure
        notebookLastPageWritten[uniqueNotebookId] = pageNumber;

        if(isPublic){
            ankyAirdrop.registerWriting("notebook", cid);
        }
        hasWrittenInInstance[msg.sender][templateId] = true;
    }


    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


    function getPageContent(uint256 notebookId, uint256 pageNumber) external view returns(UserPageContent memory) {
        return notebookInstances[notebookId].userPages[pageNumber];
    }

    // Overriding the ERC1155 transfer function to implement the non-transferability of non-virgin notebooks
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public override {
        require(notebookInstances[id].isVirgin, "Can't transfer a non-virgin notebook");
        super.safeTransferFrom(from, to, id, amount, data);
    }

        function startWritingInNotebook(uint256 templateId) external {
        // Deduct one notebook of the template type from the user's balance
        _burn(msg.sender, templateId, 1);

        // Create a unique ID for the non-fungible notebook
        uint256 uniqueNotebookId = _notebookIds.current();
        _mint(msg.sender, uniqueNotebookId, 1, "");

        // Initialize its state
        notebookInstances[uniqueNotebookId] = NotebookInstance({
            templateId: templateId,
            userPages: new UserPageContent[](0),
            isVirgin: false
        });

        _notebookIds.increment();
    }


    function getFullNotebook(uint256 notebookId) external view returns(NotebookInstance memory notebook) {
        address tbaAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(tbaAddress != address(0), "Invalid Anky address");
        require(balanceOf(ankyAirdrop.getUsersAnkyAddress(msg.sender), notebookId) > 0, "Only the owner of the anky that stores this notebook can perform this action");
        return notebookInstances[notebookId];
    }


    function getOwnedNotebooks(address user) external view returns(uint256[] memory) {
        return ankyTbaToOwnedNotebooks[user];
    }

    function isVirgin(uint256 notebookId) external view returns(bool) {
        return notebookInstances[notebookId].isVirgin;
    }

    function getUserVirginNotebooks(address ankyTbaAddress) external view returns(uint256[] memory) {
        return ankyTbaToOwnedVirginNotebooks[ankyTbaAddress];
    }
}
