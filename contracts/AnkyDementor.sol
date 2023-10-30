// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyDementor is ERC721Enumerable, Ownable {
    uint256 public dementorPrice;

    struct DementorPage {
        uint256 creationTimestamp;
        string promptCID;
        string userWritingCID;
        uint256 writingTimestamp;
    }

    struct DementorNotebook {
        string introCID;
        DementorPage[] pages;
        uint256 currentPage;
        uint256 dementorId;
    }

    // CHANGE THIS MAPPING FROM PUBLIC TO PRIVATE IN PRODUCTION
    mapping(address => uint256[]) public userDementorIds; // Mapping from user address to list of their dementor token IDs
    mapping(uint256 => DementorNotebook) public dementorNotebooks;
    IAnkyAirdrop public ankyAirdrop;

    event DementorNotebookCreated(uint256 indexed dementorId, address indexed owner);

    constructor(address _ankyAirdrop) ERC721("AnkyDementor", "AD") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
        dementorPrice = 0.0001 ether;  // Setting the price to 0.001 ETH
    }

    modifier onlyAnkyHolder() {
        require(ankyAirdrop.balanceOf(msg.sender) > 0, "You must own an Anky");
        _;
    }

    function getUsersAnky(address query) external view returns (address) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(query);
        return usersAnkyAddress;
    }

    function setDementorPrice(uint256 _price) external onlyOwner {
        dementorPrice = _price;
    }

    function createAnkyDementorNotebook(string memory firstPageCid, uint256 randomUID) payable external  {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(msg.value >= dementorPrice, "Incorrect eth amount sent");

        uint256 newDementorId = uint256(bytes32(keccak256(abi.encodePacked(msg.sender, randomUID))));

        DementorNotebook storage newDementorNotebook = dementorNotebooks[newDementorId];
        DementorPage memory firstPage = DementorPage({
            promptCID: firstPageCid,
            userWritingCID: "",
            creationTimestamp: block.timestamp,
            writingTimestamp: 0
        });
        newDementorNotebook.pages.push(firstPage);

        newDementorNotebook.introCID = firstPageCid;
        newDementorNotebook.currentPage = 0;
        newDementorNotebook.dementorId = newDementorId;

        _mint(usersAnkyAddress, newDementorId);
        userDementorIds[usersAnkyAddress].push(newDementorId);

        emit DementorNotebookCreated(newDementorId, usersAnkyAddress);
    }

    function getCurrentPage(uint256 dementorNotebookId) external view returns (DementorPage memory, uint256) {
        require(_exists(dementorNotebookId), "Invalid tokenId");
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(ownerOf(dementorNotebookId) == usersAnkyAddress, "Not the owner of this dementor notebook");

        DementorNotebook storage notebook = dementorNotebooks[dementorNotebookId];
        return (notebook.pages[notebook.currentPage], notebook.currentPage);
    }

    function writeDementorPage(uint256 dementorNotebookId, string memory userWritingCID, string memory nextPromptCID) external onlyAnkyHolder {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(ownerOf(dementorNotebookId) == usersAnkyAddress, "Not the owner of this dementor notebook");

        DementorNotebook storage notebook = dementorNotebooks[dementorNotebookId];
        DementorPage storage currentPage = notebook.pages[notebook.currentPage];
        uint256 thisTimestamp = block.timestamp;
        currentPage.userWritingCID = userWritingCID;
        currentPage.writingTimestamp = thisTimestamp;

        // Create the new DementorPage in memory first
        DementorPage memory newPage = DementorPage({
            promptCID: nextPromptCID,
            userWritingCID: "", // Initialize this to an empty string
            creationTimestamp: thisTimestamp,
            writingTimestamp: 0  // Initialize this to zero
        });

        // Push the new page to the storage array. the dementor needs to have a max number of pages
        notebook.pages.push(newPage);
        notebook.currentPage++;
    }

    function getUserDementors() external view returns (uint256[] memory) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        return userDementorIds[usersAnkyAddress];
    }

    function getDementor(uint256 dementorId) external view returns (DementorNotebook memory) {
        require(_exists(dementorId), "Invalid tokenId");
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(ownerOf(dementorId) == usersAnkyAddress, "Not the owner of this journal");
        return dementorNotebooks[dementorId];
    }

    function doesUserOwnAnkyDementor() external view returns (bool, uint256) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesn't exist");
        require(balanceOf(usersAnkyAddress) == 1 ,"The user doesnt own an anky dementor yet");
        uint256 tempId = tokenOfOwnerByIndex(usersAnkyAddress, 0);
        require(tempId <= type(uint32).max, "Token ID exceeds uint32 range");
        uint32 thisAnkyDementorId = uint32(tempId);

        return (true, thisAnkyDementorId);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}
