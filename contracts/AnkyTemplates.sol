// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";

/**
 * @title AnkyTemplates Contract
 * @dev This contract acts as a blueprint factory for creating and managing notebook templates.
 * Each template acts as a precursor to a minted notebook, with the notebook acting as the practical implementation of the template.
 */
contract AnkyTemplates is ERC1155Supply, Ownable {

    // Maximum allowed templates per creator per day.
    uint256 public constant MAX_TEMPLATES_PER_DAY = 1;
    // Maximum allowed notebooks per template.
    uint256 public constant MAX_NOTEBOOKS_PER_TEMPLATE = 100;
    // Time period definitions.
    uint256 public constant DAY_IN_SECONDS = 86400;

    struct NotebookTemplate {
        uint32 templateId;
        address creator;
        string metadataCID;
        uint256 price;
        uint256 supply;
        uint256 numberOfPrompts;
        uint256 lastCreatedTimestamp; // Timestamp of the last created template
    }

    IAnkyAirdrop public ankyAirdrop;

    // Mapping of banned accounts.
    mapping(address => bool) public bannedCreators;

    // State variables
    address internal ankyNotebooksAddress;

    // All the templates that a particular person has added.
    mapping(address => uint32[]) public templatesByCreator;
    // All the templates in relationship to their id.
    mapping(uint32 => NotebookTemplate) public templates;
    // This mapping is for fetching all the notebooks that have been minted of a particular template
    mapping(uint32 => uint32[]) public instancesOfTemplate;

    event TemplateCreated(uint32 templateId, address creator, uint256 supply, uint256 price, string metadataCID);

    constructor(address _ankyAirdrop) ERC1155("https://api.anky.io/templates/{id}.json") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
    }

    // Modifiers
    modifier onlyAnkyNotebooks() {
        require(msg.sender == ankyNotebooksAddress, "Not authorized");
        _;
    }

    modifier notBanned() {
        require(!bannedCreators[msg.sender], "You are banned from creating templates.");
        _;
    }

    // Set the address for the AnkyNotebooks contract
    function setAnkyNotebooksAddress(address _ankyNotebooksAddress) external onlyOwner {
        ankyNotebooksAddress = _ankyNotebooksAddress;
    }

    // Ban an account from creating templates.
    function banCreator(address creator) external onlyOwner {
        bannedCreators[creator] = true;
    }

    // Unban an account from creating templates.
    function unbanCreator(address creator) external onlyOwner {
        bannedCreators[creator] = false;
    }

    // Return current supply of a particular template.
    function getTemplateCurrentSupply(uint32 templateId) external view returns (uint256) {
        return templates[templateId].supply;
    }

    // Create a new template.
    function createTemplate(uint256 price, string memory metadataCID, uint256 supply, uint256 numberOfPrompts, uint256 randomUID ) external notBanned {
        require(supply > 0 && supply <= MAX_NOTEBOOKS_PER_TEMPLATE, "Invalid supply");
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "You must own an Anky to create a notebook template");

        uint32 newTemplateId = uint32(bytes4(keccak256(abi.encodePacked(msg.sender, randomUID))));

        templates[newTemplateId] = NotebookTemplate({
            templateId: newTemplateId,
            price: price,
            metadataCID: metadataCID,
            creator: msg.sender,
            supply: supply,
            numberOfPrompts:numberOfPrompts,
            lastCreatedTimestamp: block.timestamp
        });

        templatesByCreator[msg.sender].push(newTemplateId);
        emit TemplateCreated(newTemplateId, msg.sender, supply, price, metadataCID);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getTemplate(uint32 templateId) external view returns (NotebookTemplate memory) {
        return templates[templateId];
    }

    function getTemplatesByCreator(address creator) external view returns(uint32[] memory) {
        return templatesByCreator[creator];
    }

    // Called when an instance of a template is being minted.
    function mintTemplateInstance(uint32 templateId, uint32 instanceId) external onlyAnkyNotebooks {
        require(templates[templateId].supply > 0, "All instances of this template have been minted");
        instancesOfTemplate[templateId].push(instanceId);
        templates[templateId].supply--;
    }
}
