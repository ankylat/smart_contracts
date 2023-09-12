// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyTemplates is ERC1155Supply, Ownable {

    struct NotebookTemplate {
        uint256 templateId;
        address creator;
        string metadataURI;
        uint256 price;
        string[] prompts; // The ordered prompts/questions for each page
        //uint256 supply;
    }

    IAnkyAirdrop public ankyAirdrop;
    address public ankyNotebooksAddress;

    mapping(uint256 => NotebookTemplate) public templates;
    // This mapping is for fetching all the notebooks that have been minted of a particular template
    mapping(uint256 => uint256[]) public instancesOfTemplate;
    // The following mapping is the unique source of truth of the supply that is left for each one of the notebooks.
    mapping(uint256 => uint256) public templateSupply;
    uint256 public templateCount = 0;

    event TemplateCreated(uint256 templateId, address creator, uint256 supply, uint256 price, string metadataURI);

    constructor(address _ankyAirdrop) ERC1155("https://yourmetadata.uri/templates/{id}.json") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
    }

    modifier onlyAnkyNotebooks() {
        require(msg.sender == ankyNotebooksAddress, "Not authorized");
        _;
    }

     function setAnkyNotebooksAddress(address _ankyNotebooksAddress) external onlyOwner {
        ankyNotebooksAddress = _ankyNotebooksAddress;
    }

    function getTemplateSupply(uint256 templateId) external view returns (uint256) {
        return templateSupply[templateId];
    }

      function createTemplate(uint256 price, string[] memory prompts, string memory metadataURI, uint256 supply) external {
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "You must own an Anky to create a notebook template");

        templates[templateCount] = NotebookTemplate({
            templateId: templateCount,
            price: price,
            metadataURI: metadataURI,
            creator: msg.sender,
            prompts: prompts
            //supply: supply
        });
        templateSupply[templateCount] = supply;
        emit TemplateCreated(templateCount, msg.sender, supply, price, metadataURI);
        templateCount++;
    }

    function getTemplate(uint256 templateId) external view returns (NotebookTemplate memory) {
        return templates[templateId];
    }

    function getTemplatePrompt(uint256 templateId, uint256 pageNumber) external view returns (string memory) {
        require(templates[templateId].prompts.length > pageNumber, "Page number out of bounds");
        return templates[templateId].prompts[pageNumber];
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
