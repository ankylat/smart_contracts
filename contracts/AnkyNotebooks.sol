// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing OpenZeppelin contracts for standard ERC1155 functionality and ownership control
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Importing the AnkyAirdrop interface
import "./interfaces/AnkyAirdrop.sol";

/*
COMMENTS ABOUT THE SMART CONTRACT IMPLEMENTATION FOR THE NOTEBOOKS:

The AnkyNotebooks smart contract serves as the backbone of the Anky project's notebook functionality, providing users with the ability to create, mint, and modify digital notebooks. Each notebook is implemented as a non-fungible token (NFT) based on the ERC-1155 standard, which allows for both fungible and non-fungible tokens within a single contract. This contract is built with extensibility and scalability in mind to support the evolving needs of the Anky ecosystem. Specifically, the contract allows for the creation of notebook templates, which are meta-representations of notebooks that can be minted into actual notebook instances by users. Notebook templates contain essential information such as the creator's address, metadata URI, the number of pages, and the minting price. Notebook instances, on the other hand, are minted from these templates and can be owned, transferred, and modified (written into) by users. The contract also integrates with the AnkyAirdrop contract to ensure that only Anky holders can create notebook templates, thereby strengthening the ecosystem and adding value to Anky ownership. Overall, the contract aims to facilitate the creation and management of digital notebooks in a decentralized manner, while also integrating seamlessly with the broader Anky project.

*/

contract AnkyNotebooks is ERC1155Supply, Ownable {
    struct NotebookTemplate {
        address creator;
        string metadataURI;
        uint256 numPages;
        uint256 price; // What is the unit of the prize?
        uint256 supply;
    }

    struct NotebookInstance {
        address ankyKeeperTbaAddress;
        uint256 templateId;
        mapping(uint256 => string) pages;
    }

    IAnkyAirdrop public ankyAirdrop;
    address public platformAddress;

    mapping(uint256 => NotebookTemplate) public notebookTemplates;
    mapping(uint256 => NotebookInstance) public notebookInstances;
    // This mapping is for fetching all the notebooks that have been minted of a particular template
    mapping(uint256 => uint256[]) public instancesOfTemplate;
    // This mapping is for storing all the notebooks that a particular address owns.
    mapping(address => uint256[]) public ankyToOwnedNotebooks;

    uint256 nextTemplateId = 1;
    uint256 nextInstanceId = 1;
    mapping(uint256 => uint256) public templateSupply;

    event NotebookTemplateCreated(uint256 indexed templateId, address indexed creator, uint256 price, uint256 supply);
    event NotebookInstanceMinted(uint256 indexed instanceId, address indexed owner,  uint256 indexed templateId);

    constructor(address _ankyAirdrop) ERC1155("https://yourmetadata.uri/{id}.json") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
        platformAddress = msg.sender;
    }

  function createNotebookTemplate(string memory metadataURI, uint256 numPages, uint256 supply) external payable {
    // Ensure the user owns an Anky by checking the first token
    require(ankyAirdrop.balanceOf(msg.sender) != 0, "You must own an Anky to create a notebook template");

    // Hardcoded price in wei. 0.001 ETH is 10^15 wei.
        uint256 price = 1e15;
        require(msg.value >= price, "Insufficient fee sent");

        notebookTemplates[nextTemplateId] = NotebookTemplate({
            creator: msg.sender,
            metadataURI: metadataURI,
            numPages: numPages,
            price: price,
            supply: supply
        });

        emit NotebookTemplateCreated(nextTemplateId, msg.sender, price, supply);
        nextTemplateId++;
    }

 function mintNotebookInstance(address ankyTba, uint256 templateId, uint256 amount) external payable {

        require(ankyAirdrop.balanceOf(msg.sender) != 0, "Address needs to own an Anky to mint a notebook");
        address tbaAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(tbaAddress == ankyTba, "You are not the owner of this Anky");
        require(amount > 0 && amount <= 5, "You can mint between 1 to 5 notebooks");

        NotebookTemplate storage notebookTemplate = notebookTemplates[templateId];
        require(notebookTemplate.creator != address(0), "Invalid templateId");

        uint256 totalPrice = notebookTemplate.price * amount;
        require(msg.value >= totalPrice, "Insufficient Ether sent");

        // Check supply constraints
        require(notebookTemplate.supply >= amount, "Insufficient supply");
        notebookTemplate.supply -= amount;

        for (uint256 i = 0; i < amount; i++) {
            // Initialize the struct manually to avoid Solidity's restrictions on nested mappings in storage
            NotebookInstance storage instance = notebookInstances[nextInstanceId];
            instance.templateId = templateId;

            _mint(tbaAddress, nextInstanceId, 1, "");
            // To save all of the instances of a template that have been generated and then be able to display it on the front end.
            instancesOfTemplate[templateId].push(nextInstanceId);
            ankyToOwnedNotebooks[tbaAddress].push(templateId);
            emit NotebookInstanceMinted(nextInstanceId, tbaAddress, templateId);

            nextInstanceId++;
        }

        uint256 creatorShare = (totalPrice * 10) / 100;
        uint256 userShare = (totalPrice * 70) / 100;

        // Send part of the minting price back to the creator of the notebook template
        payable(notebookTemplate.creator).transfer(creatorShare);
        // Send part of the minting price paid back to the anky that is minting the notebook
        // The problem here lies with the interactions of the TBA with the call of the functions. Who is the one that owns the money with which the call is made? Is it the address that owns the Anky or is it the Anky? If it is the Anky, how can we call the function "from" the anky but give the user the rights to do that? I just think it is a better strategy to work with the user's wallet. That's why it is implemented like this atm.
        payable(msg.sender).transfer(userShare);

    }

    function writePage(uint256 instanceId, uint256 pageNumber, string memory content) external {
        // Instance of the notebook.
        require(_exists(instanceId), "Instance doesn't exist");
        // Only the owner of the anky can write in the page that is inside
        address tbaAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(tbaAddress == ownerOf(instanceId), "Only the owner of the Anky that owns this notebook can write");

        NotebookInstance storage notebookInstance = notebookInstances[instanceId];
        notebookInstance.pages[pageNumber] = content;
    }

    // This serves the purpose of getting all of the templates that have been created.
    function getInstancesOfTemplate(uint256 templateId) external view returns (uint256[] memory) {
        return instancesOfTemplate[templateId];
    }

     function userBalanceOfAnky(address userAddress) external view returns(uint256){
        return ankyAirdrop.balanceOf(userAddress);
    }

    // Implement the isApprovedForAll function, to check for operator approval
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    function calculatePrice(uint256 numPages) public pure returns (uint256) {
        return numPages * numPages * 10**16;
    }

    function _exists(uint256 instanceId) internal view returns (bool) {
        return notebookInstances[instanceId].templateId != 0;
    }

    function ownerOf(uint256 instanceId) public pure returns (address) {
        return address(uint160(instanceId));
    }

    // To withdraw part of the $ that is on the smart contract.
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient funds");
        payable(owner()).transfer(amount);
    }

    // To withdraw the funds from the smart contract to the owner of it, which will eventually be the DAO
    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getTotalTemplates() public view returns (uint256) {
        return nextTemplateId - 1;
    }
    function getTotalInstances() public view returns (uint256) {
        return nextInstanceId - 1;
    }
}
