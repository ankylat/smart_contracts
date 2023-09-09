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

    struct NotebookInstance {
        uint256 templateId;
        mapping(uint256 => string) pages;
        bool isVirgin;
    }

    IAnkyAirdrop public ankyAirdrop;
    AnkyTemplates public ankyTemplates;
    Counters.Counter private _notebookIds;

    mapping(uint256 => NotebookInstance) public notebookInstances;
     // This mapping is for storing all the notebooks that a particular anky tba owns.
    mapping(address => uint256[]) public ankyTbaToOwnedNotebooks;

    event NotebookMinted(uint256 indexed instanceId, address indexed owner, uint256 indexed templateId);

    constructor(address _ankyAirdrop, address _ankyTemplates) ERC721("Anky Notebooks", "ANKYNB") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
        ankyTemplates = AnkyTemplates(_ankyTemplates);
    }

   function mintNotebook(address ankyTba, uint256 templateId, uint256 amount) external payable {
    require(ankyAirdrop.balanceOf(msg.sender) != 0, "Address needs to own an Anky to mint a notebook");
    address tbaAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
    require(tbaAddress == ankyTba, "You are not the owner of this Anky");
    require(amount > 0 && amount <= 5, "You can mint between 1 to 5 notebooks");

    AnkyTemplates.NotebookTemplate memory notebookTemplate = ankyTemplates.getTemplate(templateId);
    require(notebookTemplate.creator != address(0), "Invalid templateId");

    uint256 totalPrice = notebookTemplate.price * amount;
    require(msg.value >= totalPrice, "Insufficient Ether sent");

    // Check supply constraints
    require(notebookTemplate.supply >= amount, "Insufficient supply");
    notebookTemplate.supply -= amount;

    for (uint256 i = 0; i < amount; i++) {
        uint256 newNotebookId = _notebookIds.current();

        notebookInstances[newNotebookId] = NotebookInstance({
            templateId: templateId,
            isVirgin: true
        });

        _mint(tbaAddress, newNotebookId);
        ankyTemplates.addInstanceToTemplate(templateId, newNotebookId); // Update this line
        ankyTbaToOwnedNotebooks[tbaAddress].push(templateId);

        emit NotebookMinted(newNotebookId, tbaAddress, templateId);
        _notebookIds.increment();
    }

    uint256 creatorShare = (totalPrice * 10) / 100;
    uint256 userShare = (totalPrice * 70) / 100;

    payable(notebookTemplate.creator).transfer(creatorShare);
    payable(msg.sender).transfer(userShare);
}


    function writePage(uint256 notebookId, uint256 pageNumber, string memory content) external {
        require(ownerOf(notebookId) == ankyAirdrop.getUsersAnkyAddress(msg.sender), "Only the owner can write");
        NotebookInstance storage notebookInstance = notebookInstances[notebookId];

        notebookInstance.pages[pageNumber] = content;
        if(notebookInstance.isVirgin) {
            notebookInstance.isVirgin = false;
        }
    }

    function isVirgin(uint256 notebookId) external view returns(bool) {
        return notebookInstances[notebookId].isVirgin;
    }

    function getWrittenPage(uint256 notebookId, uint256 pageNumber) external view returns(string memory) {
        return notebookInstances[notebookId].pages[pageNumber];
    }
}
