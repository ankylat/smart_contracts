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
        uint256 price;
        string[] prompts; // The ordered prompts/questions for each page
        uint256 supply;
    }

    IAnkyAirdrop public ankyAirdrop;
    address public ankyNotebooksAddress;

    mapping(uint256 => NotebookTemplate) public templates;
    // This mapping is for fetching all the notebooks that have been minted of a particular template
    mapping(uint256 => uint256[]) public instancesOfTemplate;
    // The supply that is left for each one of these templates
    mapping(uint256 => uint256) public templateSupply;
    uint256 public templateCount = 0;

    event TemplateCreated(uint256 templateId, address creator, uint256 supply, uint256 price, string metadataURI);

    constructor(address _ankyAirdrop, address _ankyNotebooksAddress) ERC1155("https://yourmetadata.uri/templates/{id}.json") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
        ankyNotebooksAddress = _ankyNotebooksAddress;
    }

    modifier onlyAnkyNotebooks() {
        require(msg.sender == ankyNotebooksAddress, "Not authorized");
        _;
    }

     function setAnkyNotebooksAddress(address _ankyNotebooksAddress) external onlyOwner {
        ankyNotebooksAddress = _ankyNotebooksAddress;
    }

      function createTemplate(uint256 price, string[] memory prompts, string memory metadataURI, uint256 supply) external {
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "You must own an Anky to create a notebook template");

        templates[templateCount] = NotebookTemplate({
            price: price,
            metadataURI: metadataURI,
            creator: msg.sender,
            prompts: prompts,
            supply: supply
        });

        emit TemplateCreated(templateCount, msg.sender, supply, price, metadataURI);
        templateCount++;
    }

    function getTemplate(uint256 templateId) external view returns (NotebookTemplate memory) {
        return templates[templateId];
    }

    function getNumPagesOfTemplate(uint256 templateId) external view returns(uint256) {
        return templates[templateId].prompts.length;
    }

    // Inside the AnkyTemplates contract
    function addInstanceToTemplate(uint256 templateId, uint256 instanceId) external onlyAnkyNotebooks {
        instancesOfTemplate[templateId].push(instanceId);
        templateSupply[templateId]--;
    }

}
