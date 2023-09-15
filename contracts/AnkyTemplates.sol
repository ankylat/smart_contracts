// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyTemplates is ERC1155Supply, Ownable {

    struct NotebookTemplate {
        uint256 templateId;
        address creator;
        string metadataCID;
        uint256 price;
        uint256 supply;
        uint256 numberOfPrompts;
    }

    IAnkyAirdrop public ankyAirdrop;
    address public ankyNotebooksAddress;

    // All the templates that a particular person has added.
    mapping(address => uint256[]) public templatesByCreator;
    // All the templates in relationship to their id.
    mapping(uint256 => NotebookTemplate) public templates;
    // This mapping is for fetching all the notebooks that have been minted of a particular template
    mapping(uint256 => uint256[]) public instancesOfTemplate;

    uint256 public templateCount = 0;

    event TemplateCreated(uint256 templateId, address creator, uint256 supply, uint256 price, string metadataCID);

    constructor(address _ankyAirdrop) ERC1155("https://yourmetadata.uri/templates/{id}.json") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
    }

    // Enforcing the relationship between this contract and the AnkyNotebooks one.
    modifier onlyAnkyNotebooks() {
        require(msg.sender == ankyNotebooksAddress, "Not authorized");
        _;
    }

    // Establishing the relationship between this contract and the AnkyNotebooks one.
     function setAnkyNotebooksAddress(address _ankyNotebooksAddress) external onlyOwner {
        ankyNotebooksAddress = _ankyNotebooksAddress;
    }

    // How many templates are left for a particular one?
    function getTemplateCurrentSupply(uint256 templateId) external view returns (uint256) {
        return templates[templateId].supply;
    }

    // For creating a template / blueprint.
      function createTemplate(uint256 price, string memory metadataCID, uint256 supply, uint256 numberOfPrompts) external {
        require(supply > 0, "Supply of the template must be positive");
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "You must own an Anky to create a notebook template");

        templates[templateCount] = NotebookTemplate({
            templateId: templateCount,
            price: price,
            metadataCID: metadataCID,
            creator: msg.sender,
            supply: supply,
            numberOfPrompts:numberOfPrompts
        });
        templatesByCreator[msg.sender].push(templateCount);
        emit TemplateCreated(templateCount, msg.sender, supply, price, metadataCID);
        templateCount++;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getTemplate(uint256 templateId) external view returns (NotebookTemplate memory) {
        return templates[templateId];
    }

    function getTemplatesByCreator(address creator) external view returns(uint256[] memory) {
        return templatesByCreator[creator];
    }

    function addInstanceToTemplate(uint256 templateId, uint256 instanceId) external onlyAnkyNotebooks {
        instancesOfTemplate[templateId].push(instanceId);
        templates[templateId].supply--; // Update supply in the struct.
    }

}
