// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing required modules and contracts.
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";

// AnkyNotebooks contract that extends both ERC1155 (for multi-token support) and Ownable (for administrative functions).
contract AnkyNotebooks is ERC1155, Ownable {

    // Struct for Notebook type that contains its metadata.
    struct Notebook {
        address creator;
        string metadataCID;
        uint256 originalFungibleNotebookId;
    }

    // Struct for storing written page data.
    struct Page {
        string cid; // CID pointing to content in Arweave where the writing for this page is stored.
        uint256 timestamp; // Timestamp of when the page was written.
    }

    // Reference to the AnkyAirdrop contract.
    IAnkyAirdrop public ankyAirdrop;

    // Mappings to organize data:
    uint256[] public fungibleNotebookIds;
    mapping(uint256 => Notebook) public fungibleNotebooks;
    mapping(uint256 => Notebook) public nonFungibleNotebooks;
    mapping(uint256 => uint256) public lastWrittenPageIndex;
    mapping(uint256 => uint256[]) public allNonFungibleNotebooksFromFungibleNotebook;
    mapping(address => uint256[]) public notebooksOwnedByAnky;
    mapping(uint256 => Page[]) public writtenNotebookPages;
    mapping(uint256 => mapping(uint256 => bool)) public derivedNotebookExists;
    mapping(uint256 => uint256) public fungibleNotebookSupply;

    // Do we need a mapping that checks all of the anky addresses that own a particular non fungible notebook derived from the same fungible one?

    // Events to log significant actions on the blockchain.
    event NotebookCreated(string uuid, address creator, uint256 supply, uint256 fungibleNotebookId);
    event NotebookTransformedToNFT(uint256 nonFungibleNotebookId, uint256 fungibleNotebookId, address usersAnkyAddress);
    event PageWritten(uint256 nonFungibleNotebookId, string cid, uint256 timestamp);

    // Constructor to initialize the contract with a reference to AnkyAirdrop and setting base URI for ERC1155.
    constructor(address _ankyAirdrop) ERC1155("https://api.anky.lat/notebooks/{id}.json") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
    }

    // Function to create a new type of notebook. It accepts a uuit as a string and transforms it into a number.
    function createNotebook(string memory uuid, uint256 supply, string memory _metadataCID) external {
        require(supply > 0 && supply <= 88, "supply out of range");
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "Address needs to own an Anky to create a notebook type");
        address ankyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(ankyAddress != address(0), "Invalid anky address");

        uint256 newFungibleNotebookId = uint256(keccak256(bytes(uuid)));

        require(fungibleNotebooks[newFungibleNotebookId].creator == address(0), "Notebook already exists.");

        fungibleNotebooks[newFungibleNotebookId].creator = msg.sender;
        fungibleNotebooks[newFungibleNotebookId].originalFungibleNotebookId = 0;
        fungibleNotebooks[newFungibleNotebookId].metadataCID = _metadataCID;

        fungibleNotebookSupply[newFungibleNotebookId] = supply;
        fungibleNotebookIds.push(newFungibleNotebookId);

        _mint(ankyAddress, newFungibleNotebookId, supply, "");

        emit NotebookCreated(uuid, msg.sender, supply, newFungibleNotebookId);
    }

    // Private helper function to generate a unique ID for the NFT.
    function generateNFTId(uint256 fungibleNotebookId, address ankyAddress) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(fungibleNotebookId, ankyAddress)));
    }

    // Function to transform a fungible notebook to a unique NFT on which someone will write.
    function transformNotebookToNFT(uint256 fungibleNotebookId) external {
        address ankyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(balanceOf(ankyAddress, fungibleNotebookId) > 0, "Must own a fungible notebook of these to burn it.");
        uint256 newNonFungibleNotebookId = generateNFTId(fungibleNotebookId, ankyAddress);
        require(balanceOf(ankyAddress, newNonFungibleNotebookId) == 0, "You already own a non fungible notebook derived from this fungible one");

        nonFungibleNotebooks[newNonFungibleNotebookId] = fungibleNotebooks[fungibleNotebookId];
        nonFungibleNotebooks[newNonFungibleNotebookId].originalFungibleNotebookId = fungibleNotebookId;

        _burn(ankyAddress, fungibleNotebookId, 1);
        _mint(ankyAddress, newNonFungibleNotebookId, 1, "");

        allNonFungibleNotebooksFromFungibleNotebook[fungibleNotebookId].push(newNonFungibleNotebookId);
        notebooksOwnedByAnky[ankyAddress].push(newNonFungibleNotebookId);
        derivedNotebookExists[fungibleNotebookId][newNonFungibleNotebookId] = true;

        fungibleNotebookSupply[fungibleNotebookId] -= 1;

        emit NotebookTransformedToNFT(newNonFungibleNotebookId, fungibleNotebookId, ankyAddress);
    }

    // Function to allow users to write in their unique notebooks.
    function writePage(uint256 nonFungibleTokenId, string memory cid, bool userWantsItToBePublic) external {
        address ankyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(balanceOf(ankyAddress, nonFungibleTokenId) > 0, "You must own this notebook to write on it.");

        uint256 nextPage = lastWrittenPageIndex[nonFungibleTokenId] + 1;        // Add the written page.

        require(writtenNotebookPages[nonFungibleTokenId].length == nextPage, "Must write sequentially.");

        writtenNotebookPages[nonFungibleTokenId].push(Page({
            cid: cid,
            timestamp: block.timestamp
        }));

        lastWrittenPageIndex[nonFungibleTokenId]++;

        emit PageWritten(nonFungibleTokenId, cid, block.timestamp);

        // Optionally, make the writing public.
        if(userWantsItToBePublic){
            ankyAirdrop.registerWriting("notebook", cid);
        }
    }

    function isDerivedFromOriginal(uint256 nonFungibleNotebookId, uint256 originalFungibleId) private view returns (bool) {
        return derivedNotebookExists[originalFungibleId][nonFungibleNotebookId];
    }

    function getAllFungibleNotebooks() public view returns (
        uint256[] memory ids,
        address[] memory creators,
        string[] memory metadataCIDs,
        uint256[] memory originalFungibleNotebookIds
    ) {
        uint256 length = fungibleNotebookIds.length;

        ids = new uint256[](length);
        creators = new address[](length);
        metadataCIDs = new string[](length);
        originalFungibleNotebookIds = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 notebookId = fungibleNotebookIds[i];
            ids[i] = notebookId;
            creators[i] = fungibleNotebooks[notebookId].creator;
            metadataCIDs[i] = fungibleNotebooks[notebookId].metadataCID;
            originalFungibleNotebookIds[i] = fungibleNotebooks[notebookId].originalFungibleNotebookId;
        }

        return (ids, creators, metadataCIDs, originalFungibleNotebookIds);
    }

    function getAllNotebooksFromSameFungibleNotebook(uint256 nonFungibleNotebookId) public view returns (uint256[] memory) {
        uint256 originalNotebookId = nonFungibleNotebooks[nonFungibleNotebookId].originalFungibleNotebookId;
        return allNonFungibleNotebooksFromFungibleNotebook[originalNotebookId];
    }


    function viewFullNotebook(uint256 nonFungibleNotebookId) external view returns(Page[] memory) {
        address ankyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        uint256 originalFungibleNotebookId = nonFungibleNotebooks[nonFungibleNotebookId].originalFungibleNotebookId;

        require(
            balanceOf(ankyAddress, nonFungibleNotebookId) > 0 ||
            isDerivedFromOriginal(nonFungibleNotebookId, originalFungibleNotebookId),
            "You can't access this information."
        );

        return writtenNotebookPages[nonFungibleNotebookId];
    }


    function getTotalPagesWritten(uint256 nonFungibleTokenId) external view returns(uint256) {
        return writtenNotebookPages[nonFungibleTokenId].length;
    }

    function getNotebooksOfAnky(address ankyAddress) external view returns(uint256[] memory) {
        return notebooksOwnedByAnky[ankyAddress];
    }
    // Override function to prevent transfer of written notebooks.
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public override {
        if(nonFungibleNotebooks[id].creator != address(0)) {  // Checking if id exists in nonFungibleNotebooks
            require(
                nonFungibleNotebooks[id].originalFungibleNotebookId != 0,
                "Cannot transfer a derived non-fungible notebook."
            );
        }
        super.safeTransferFrom(from, to, id, amount, data);
    }

}

