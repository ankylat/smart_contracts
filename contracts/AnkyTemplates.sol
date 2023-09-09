// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";

/*
The AnkyTemplates smart contract serves as a repository for notebook templates created by users owning an Anky. Every template contains metadata like the creator's address, associated metadata URI, the number of pages it has, its price, and the supply. This contract acts as an ERC1155 token, which means each template has an ID and can have multiple supplies. The instancesOfTemplate mapping provides an efficient way to fetch all notebook instances minted from a particular template. This contract ensures that only valid Anky owners can create templates and integrates with the AnkyAirdrop contract to verify Anky ownership.
 */

contract AnkyTemplates is ERC1155Supply, Ownable {

    struct NotebookTemplate {
        address creator;
        string metadataURI;
        uint256 numPages;
        uint256 price;
        uint256 supply;
    }

    IAnkyAirdrop public ankyAirdrop;
    address public ankyNotebooksAddress;

    mapping(uint256 => NotebookTemplate) public notebookTemplates;
    // This mapping is for fetching all the notebooks that have been minted of a particular template
    mapping(uint256 => uint256[]) public instancesOfTemplate;
    // The supply that is left for each one of these templates
    mapping(uint256 => uint256) public templateSupply;
    uint256 nextTemplateId = 1;

    event NotebookTemplateCreated(uint256 indexed templateId, address indexed creator, uint256 numPages, uint256 supply);

    constructor(address _ankyAirdrop, address _ankyNotebooksAddress) ERC1155("https://yourmetadata.uri/templates/{id}.json") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
        ankyNotebooksAddress = _ankyNotebooksAddress;
    }

    modifier onlyAnkyNotebooks() {
        require(msg.sender == ankyNotebooksAddress, "Not authorized");
        _;
    }

    function createNotebookTemplate(string memory metadataURI, uint256 numPages, uint256 price, uint256 supply) external {
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "You must own an Anky to create a notebook template");

        notebookTemplates[nextTemplateId] = NotebookTemplate({
            creator: msg.sender,
            metadataURI: metadataURI,
            numPages: numPages,
            price: price,
            supply: supply
        });

        emit NotebookTemplateCreated(nextTemplateId, msg.sender, numPages, supply);
        nextTemplateId++;
    }

    function getTemplate(uint256 templateId) external view returns (NotebookTemplate memory) {
        return notebookTemplates[templateId];
    }

    // Inside the AnkyTemplates contract
    function addInstanceToTemplate(uint256 templateId, uint256 instanceId) external onlyAnkyNotebooks {
        instancesOfTemplate[templateId].push(instanceId);
    }

}
