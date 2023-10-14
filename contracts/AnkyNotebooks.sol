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

    struct UserPageContent {
        string arweaveCID;      // URL pointing to the user's answer on Arweave
        uint256 timestamp;      // The time when the content was added
    }

    struct NotebookInstance {
        uint256 templateId;
        uint256 notebookId;
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
    event PageWritten(uint256 indexed notebookId, uint256 indexed pageNumber, string arweaveURL, uint256 timestamp);

    // constructor(address _ankyAirdrop, address _ankyTemplates, address _gelatoRelay) ERC721("Anky Notebooks", "ANKYNB") GelatoRelayContextERC2771(_gelatoRelay) {
    //     ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
    //     ankyTemplates = AnkyTemplates(_ankyTemplates);
    // }
    constructor(address _ankyAirdrop, address _ankyTemplates) ERC721("Anky Notebooks", "ANKYNB")  {
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
        notebookInstances[currentNotebookId].notebookId = currentNotebookId;
        notebookInstances[currentNotebookId].isVirgin = true;
        notebookLastPageWritten[currentNotebookId] = 0;

        _mint(tbaAddress, currentNotebookId);
        ankyTemplates.mintTemplateInstance(templateId, currentNotebookId);
        ankyTbaToOwnedNotebooks[tbaAddress].push(currentNotebookId);

        emit NotebookMinted(currentNotebookId, tbaAddress, templateId);
        _notebookIds.increment();


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

    function writeNotebookPage(uint256 notebookId, uint256 pageNumber, string memory arweaveCID, bool userWantsPublic) external onlyNotebookOwner(notebookId) {
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

        notebookInstance.userPages.push(UserPageContent({
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


    function getPageContent(uint256 notebookId, uint256 pageNumber) external view returns(UserPageContent memory) {
        return notebookInstances[notebookId].userPages[pageNumber];
    }


    function getFullNotebook(uint256 notebookId) external view returns(NotebookInstance memory notebook) {
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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 tokenBatch) internal override {
        super._beforeTokenTransfer(from, to, tokenId, tokenBatch);
        // Check if it's a transfer action (not mint or burn)
        require(notebookInstances[tokenId].isVirgin, "Can't transfer a non-virgin notebook");
    }


    function getOwnedNotebooks(address user) external view returns(uint256[] memory) {
        return ankyTbaToOwnedNotebooks[user];
    }

    function isVirgin(uint256 notebookId) external view returns(bool) {
        return notebookInstances[notebookId].isVirgin;
    }

    // function _msgSender()
    //     internal
    //     view
    //     override(Context, ERC2771Context)
    //     returns (address)
    // {
    //     return ERC2771Context._msgSender();
    // }

    // function _msgData()
    //     internal
    //     view
    //     override(Context, ERC2771Context)
    //     returns (bytes calldata)
    // {
    //     return ERC2771Context._msgData();
    // }
}
