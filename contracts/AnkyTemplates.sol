// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyTemplates is ERC1155, Ownable {

    // Maximum allowed templates per creator per day.
    uint256 public constant MAX_TEMPLATES_PER_DAY = 1;
    // Maximum allowed notebooks per template.
    uint256 public constant MAX_NOTEBOOKS_PER_TEMPLATE = 100;
    // Time period definitions.
    uint256 public constant DAY_IN_SECONDS = 86400;

    struct NotebookTemplate {
        uint256 templateId;
        address creator;
        string metadataCID;
        uint256 price;
        uint256 initialSupply;
        uint256 supply;
        uint256 numberOfPrompts;
        uint256 lastCreatedTimestamp; // Timestamp of the last created template
    }

    IAnkyAirdrop public ankyAirdrop;

    // Mapping of banned accounts.
    mapping(address => bool) public bannedCreators;

    // State variables
    address internal ankyNotebooksAddress;
    uint256 public templateCount = 0;

    // All the templates that a particular person has added.
    mapping(address => uint256[]) public templatesByCreator;
    // All the templates in relationship to their id.
    mapping(uint256 => NotebookTemplate) public templates;
    // track notebooks minted by each user from each template
    mapping(address => mapping(uint256 => uint256)) public userNotebookCounts;


    event TemplateCreated(uint256 templateId, address creator, uint256 supply, uint256 price, string metadataCID);

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
    function getTemplateCurrentSupply(uint256 templateId) external view returns (uint256) {
        return templates[templateId].supply;
    }

    // Create a new template.
    function createTemplate(uint256 price, string memory metadataCID, uint256 supply, uint256 numberOfPrompts) external notBanned {
        require(supply > 0 && supply <= MAX_NOTEBOOKS_PER_TEMPLATE, "Invalid supply");
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "You must own an Anky to create a notebook template");

        uint256 lastTemplateTimestamp = templatesByCreator[msg.sender].length > 0 ? templates[templatesByCreator[msg.sender][templatesByCreator[msg.sender].length - 1]].lastCreatedTimestamp : 0;
        require(block.timestamp - lastTemplateTimestamp >= DAY_IN_SECONDS, "You can only create one template per day");

        templates[templateCount] = NotebookTemplate({
            templateId: templateCount,
            price: price,
            metadataCID: metadataCID,
            creator: msg.sender,
            initialSupply: supply,
            supply: supply,
            numberOfPrompts:numberOfPrompts,
            lastCreatedTimestamp: block.timestamp
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

    function mintTemplateToken(address account, uint256 templateId, uint256 amount, bytes memory data) external onlyAnkyNotebooks {
        require(templates[templateId].supply - amount >= 0, "There is not enough templates left");
        _mint(account, templateId, amount, data);
        uint256 currentSupply = templates[templateId].supply;
        templates[templateId].supply =  currentSupply - amount;
    }

    // Called when an instance of a template is being minted.
    function mintTemplateInstance(uint256 templateId) external onlyAnkyNotebooks {
    }
}
