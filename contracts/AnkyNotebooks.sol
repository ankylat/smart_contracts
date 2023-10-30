// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";
import "./AnkyTemplates.sol";

// The AnkyNotebooks are the ones that are minted from the AnkyTemplates
contract AnkyNotebooks is ERC721Enumerable, Ownable {
    // Check for conflicts between these imports. overwrite the methods.
    using Counters for Counters.Counter;

    struct NotebookPage {
        string arweaveCID;      // URL pointing to the user's answer on Arweave
        uint256 timestamp;      // The time when the content was added
    }

    struct NotebookInstance {
        uint32 templateId;
        uint32 notebookId;
        NotebookPage[] userPages;
        bool isVirgin;
    }

    IAnkyAirdrop public ankyAirdrop;
    AnkyTemplates public ankyTemplates;
    Counters.Counter private _notebookIds;

    // This one maps the id of the notebok to the particular notebook itself.
    mapping(uint32 => NotebookInstance) public notebookInstances;
     // This mapping is for storing all the notebooks that a particular anky tba owns.
    mapping(address => uint32[]) public ankyTbaToOwnedNotebooks;
    // Track the last page written by the user for each notebook
    mapping(uint32 => uint256) public notebookLastPageWritten;

    event FundsTransferred(address recipient, uint256 amount);
    event NotebookMinted(uint32 indexed instanceId, address indexed owner, uint32 indexed templateId);
    event PageWritten(uint32 indexed notebookId, uint256 indexed pageNumber, string arweaveURL, uint256 timestamp);

    constructor(address _ankyAirdrop, address _ankyTemplates) ERC721("Anky Notebooks", "ANKYNB")  {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
        ankyTemplates = AnkyTemplates(_ankyTemplates);
    }

   function mintNotebook(address to, uint32 templateId, uint256 amount, uint256 randomUID) external payable {
        AnkyTemplates.NotebookTemplate memory notebookTemplate = ankyTemplates.getTemplate(templateId);
        // Ensure that the template was created by an account and exists.
        require(notebookTemplate.creator != address(0), "Invalid templateId");
        // Does the user own an anky?
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "Address needs to own an Anky to mint a notebook");
        // Check which is the address of the anky that the user owns
        address tbaAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(tbaAddress != address(0), "Invalid Anky address");
        require(amount == 1, "You can mint only one notebook at a time");



        // Check supply constraints
        uint256 currentSupply = notebookTemplate.supply;
        require(currentSupply >= amount, "Insufficient supply");

        uint256 totalPrice = notebookTemplate.price * amount;
        require(msg.value >= totalPrice, "Insufficient Ether sent");

        uint32 newNotebookId = uint32(bytes4(keccak256(abi.encodePacked(msg.sender, randomUID))));

        notebookInstances[newNotebookId].templateId = templateId;
        notebookInstances[newNotebookId].notebookId = newNotebookId;
        notebookInstances[newNotebookId].isVirgin = true;
        notebookLastPageWritten[newNotebookId] = 0;

        _mint(tbaAddress, newNotebookId);
        ankyTemplates.mintTemplateInstance(templateId, newNotebookId);
        ankyTbaToOwnedNotebooks[tbaAddress].push(newNotebookId);

        emit NotebookMinted(newNotebookId, tbaAddress, templateId);


        uint256 creatorShare = (totalPrice * 10) / 100;
        uint256 userShare = (totalPrice * 70) / 100;

        // Transfer back part of the money to the creator of the template and to the wallet that is minting.
        payable(notebookTemplate.creator).transfer(creatorShare);
        emit FundsTransferred(notebookTemplate.creator, creatorShare);

        payable(to).transfer(userShare);
        emit FundsTransferred(to, userShare);
    }

    modifier onlyNotebookOwner(uint32 notebookId) {
        require(ownerOf(notebookId) == ankyAirdrop.getUsersAnkyAddress(msg.sender), "Only the owner of the anky that stores this notebook can perform this action");
        _;
    }

    function writeNotebookPage(uint32 notebookId, uint256 pageNumber, string memory arweaveCID, bool userWantsPublic) external onlyNotebookOwner(notebookId) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        uint256 lastPageWritten = notebookLastPageWritten[notebookId];
        require(pageNumber == lastPageWritten, "Pages must be written in sequence");

        NotebookInstance storage notebookInstance = notebookInstances[notebookId];
        if(notebookInstances[notebookId].isVirgin) {
            notebookInstances[notebookId].isVirgin = false;
        }

        // Ensure the page hasn't been written before
        require(notebookInstance.userPages.length <= pageNumber, "Page already written or invalid page number");

        // Ensure the page is within the limit of the template's prompts
        AnkyTemplates.NotebookTemplate memory notebookTemplate = ankyTemplates.getTemplate(notebookInstance.templateId);
        require(pageNumber <= notebookTemplate.numberOfPrompts, "Page number exceeds the number of prompts for this notebook");

        notebookInstance.userPages.push(NotebookPage({
            arweaveCID: arweaveCID,
            timestamp: block.timestamp
        }));

        emit PageWritten(notebookId, pageNumber, arweaveCID, block.timestamp);  // Updated emit based on event structure
        notebookLastPageWritten[notebookId] = pageNumber + 1;
        if(userWantsPublic){
            ankyAirdrop.registerWriting(usersAnkyAddress, "notebook", arweaveCID);
        }
    }


    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


    function getPageContent(uint32 notebookId, uint256 pageNumber) external view returns(NotebookPage memory) {
        return notebookInstances[notebookId].userPages[pageNumber];
    }


    function getFullNotebook(uint32 notebookId) external view returns(NotebookInstance memory notebook) {
        address tbaAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(tbaAddress != address(0), "Invalid Anky address");
        require(ownerOf(notebookId) == tbaAddress, "Only the notebook owner can fetch its details");
        NotebookInstance storage instance = notebookInstances[notebookId];
        return NotebookInstance({
            templateId: instance.templateId,
            userPages: instance.userPages,
            notebookId: instance.notebookId,
            isVirgin: instance.isVirgin
        });
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        // Convert the firstTokenId from uint256 to uint32 safely.
        require(firstTokenId <= type(uint32).max, "Token ID is out of uint32 bounds");
        uint32 notebookId = uint32(firstTokenId);

        // Ensure it's not a batch transfer (since we're working with individual uint32 IDs)
        require(batchSize == 1, "Batch transfers are not supported");

        require(notebookInstances[notebookId].isVirgin, "Can't transfer a non-virgin notebook");
    }

    function getOwnedNotebooks(address user) external view returns(uint32[] memory) {
        return ankyTbaToOwnedNotebooks[user];
    }

    function isVirgin(uint32 notebookId) external view returns(bool) {
        return notebookInstances[notebookId].isVirgin;
    }
}
