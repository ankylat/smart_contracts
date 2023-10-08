// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing required libraries and contracts from the OpenZeppelin framework.
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";

/**
 * @title AnkyNotebooks
 * @dev This smart contract represents the AnkyNotebooks platform. It allows users to mint, transform, and write in both fungible and non-fungible notebooks.
 * Users must have an associated Anky token in the AnkyAirdrop contract to perform certain actions. It extends the ERC1155 standard for multi-token support.
 */
contract AnkyNotebooks is ERC1155, Ownable {

    // Data structure to represent a Notebook, which can be fungible or non-fungible.
    struct Notebook {
        address creator;  // Address of the notebook's creator.
        string metadataCID;  // IPFS CID for the notebook's metadata.
        uint256 originalFungibleNotebookId;  // For non-fungible notebooks, this indicates from which fungible notebook it was derived.
    }

    // Data structure to represent a page written inside a non-fungible notebook.
    struct Page {
        string cid;  // IPFS CID pointing to content where the writing for this page is stored.
        uint256 timestamp;  // Timestamp of when the page was written.
    }

    // Reference to another contract: the AnkyAirdrop contract, which holds the Anky tokens.
    IAnkyAirdrop public ankyAirdrop;

    // Arrays and mappings for organizing and accessing the data.

    // An array storing all the IDs of the fungible notebooks created.
    uint256[] public fungibleNotebookIds;

    // Mapping from notebook ID to its details.
    mapping(uint256 => Notebook) public fungibleNotebooks;
    mapping(uint256 => Notebook) public nonFungibleNotebooks;

    // Mapping from non-fungible notebook ID to the index of the last written page.
    mapping(uint256 => uint256) public lastWrittenPageIndex;

    // Mapping from fungible notebook ID to all derived non-fungible notebooks.
    mapping(uint256 => uint256[]) public allNonFungibleNotebooksFromFungibleNotebook;

    // Mapping from Anky address to all non-fungible notebooks owned by it.
    mapping(address => uint256[]) public notebooksOwnedByAnky;

    // Mapping from non-fungible notebook ID to all its written pages.
    mapping(uint256 => Page[]) public writtenNotebookPages;

    // A 2D mapping to check if a specific non-fungible notebook is derived from a specific fungible notebook.
    mapping(uint256 => mapping(uint256 => bool)) public derivedNotebookExists;

    // Mapping from fungible notebook ID to its current supply.
    mapping(uint256 => uint256) public fungibleNotebookSupply;

    // Events that will be emitted in various functions to log significant actions on the blockchain.

    // Emitted when a new fungible notebook is created.
    event NotebookCreated(string uuid, address creator, uint256 supply, uint256 fungibleNotebookId);

    // Emitted when a fungible notebook is transformed into a non-fungible one.
    event NotebookTransformedToNFT(uint256 nonFungibleNotebookId, uint256 fungibleNotebookId, address usersAnkyAddress);

    // Emitted when a page is written in a non-fungible notebook.
    event PageWritten(uint256 nonFungibleNotebookId, string cid, uint256 timestamp);

    // Constructor to set initial values: reference to the AnkyAirdrop contract and the base URI for the ERC1155 standard.
    constructor(address _ankyAirdrop) ERC1155("https://api.anky.lat/notebooks/{id}.json") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
    }

    /**
     * @dev Function to create a new fungible notebook.
     * @param uuid - A unique identifier for the notebook type.
     * @param supply - The number of copies of this fungible notebook to mint.
     * @param _metadataCID - IPFS CID for the notebook's metadata.
     */
    function createNotebook(string memory uuid, uint256 supply, string memory _metadataCID) external {
        // Conditions: supply must be within range, and the caller must have an associated Anky token in the AnkyAirdrop contract.
        require(supply > 0 && supply <= 88, "supply out of range");
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "Address needs to own an Anky to create a notebook type");

        // Get the associated Anky address of the caller.
        address ankyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(ankyAddress != address(0), "Invalid anky address");

        // Generate a unique ID for the new fungible notebook using the uuid.
        uint256 newFungibleNotebookId = uint256(keccak256(bytes(uuid)));
        require(fungibleNotebooks[newFungibleNotebookId].creator == address(0), "Notebook already exists.");

        // Set the notebook's properties.
        fungibleNotebooks[newFungibleNotebookId].creator = msg.sender;
        fungibleNotebooks[newFungibleNotebookId].originalFungibleNotebookId = 0;
        fungibleNotebooks[newFungibleNotebookId].metadataCID = _metadataCID;

        // Update supply mapping and ID array.
        fungibleNotebookSupply[newFungibleNotebookId] = supply;
        fungibleNotebookIds.push(newFungibleNotebookId);

        // Mint the specified number of this new notebook and assign them to the caller's associated Anky address.
        _mint(ankyAddress, newFungibleNotebookId, supply, "");

        // Emit an event to log this action.
        emit NotebookCreated(uuid, msg.sender, supply, newFungibleNotebookId);
    }

    /**
     * @dev Private helper function to generate a unique ID for a non-fungible notebook.
     * @param fungibleNotebookId - The ID of the fungible notebook from which the non-fungible one will be derived.
     * @param ankyAddress - The associated Anky address of the user who will own the non-fungible notebook.
     * @return - A unique ID for the new non-fungible notebook.
     */
    function generateNFTId(uint256 fungibleNotebookId, address ankyAddress) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(fungibleNotebookId, ankyAddress)));
    }

    /**
     * @dev Function to transform a fungible notebook into a non-fungible one. This allows users to write on it.
     * @param fungibleNotebookId - The ID of the fungible notebook to be transformed.
     */
    function transformNotebookToNFT(uint256 fungibleNotebookId) external {
        // Get the associated Anky address of the caller.
        address ankyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(balanceOf(ankyAddress, fungibleNotebookId) > 0, "Must own a fungible notebook of these to burn it.");

        // Generate a unique ID for the new non-fungible notebook.
        uint256 newNonFungibleNotebookId = generateNFTId(fungibleNotebookId, ankyAddress);
        require(balanceOf(ankyAddress, newNonFungibleNotebookId) == 0, "You already own a non fungible notebook derived from this fungible one");

        // Copy the details from the fungible notebook to the non-fungible one and set its original ID.
        nonFungibleNotebooks[newNonFungibleNotebookId] = fungibleNotebooks[fungibleNotebookId];
        nonFungibleNotebooks[newNonFungibleNotebookId].originalFungibleNotebookId = fungibleNotebookId;

        // Burn one instance of the fungible notebook and mint the non-fungible one.
        _burn(ankyAddress, fungibleNotebookId, 1);
        _mint(ankyAddress, newNonFungibleNotebookId, 1, "");

        // Update the mappings to keep track of the new non-fungible notebook.
        allNonFungibleNotebooksFromFungibleNotebook[fungibleNotebookId].push(newNonFungibleNotebookId);
        notebooksOwnedByAnky[ankyAddress].push(newNonFungibleNotebookId);
        derivedNotebookExists[fungibleNotebookId][newNonFungibleNotebookId] = true;

        // Decrease the supply of the fungible notebook.
        fungibleNotebookSupply[fungibleNotebookId] -= 1;

        // Emit an event to log this action.
        emit NotebookTransformedToNFT(newNonFungibleNotebookId, fungibleNotebookId, ankyAddress);
    }

     /**
     * @dev Function to allow users to write on their non-fungible notebook.
     * @param nonFungibleTokenId - The ID of the non-fungible notebook.
     * @param cid - IPFS CID pointing to the content of the written page.
     * @param userWantsItToBePublic - A flag to indicate if the user wants the written content to be publicly accessible.
     */
    function writePage(uint256 nonFungibleTokenId, string memory cid, bool userWantsItToBePublic) external {
        // Fetch the associated Anky address of the caller.
        address ankyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);

        // Ensure that the caller owns the non-fungible notebook they want to write in.
        require(balanceOf(ankyAddress, nonFungibleTokenId) > 0, "You must own this notebook to write on it.");

        // Determine the index of the next page to be written.
        uint256 nextPage = lastWrittenPageIndex[nonFungibleTokenId] + 1;

        // Ensure that pages are written in sequential order without skipping.
        require(writtenNotebookPages[nonFungibleTokenId].length == nextPage, "Must write sequentially.");

        // Add the new page to the written pages of the non-fungible notebook.
        writtenNotebookPages[nonFungibleTokenId].push(Page({
            cid: cid,
            timestamp: block.timestamp
        }));

        // Update the index of the last written page.
        lastWrittenPageIndex[nonFungibleTokenId]++;

        // Emit an event logging the action.
        emit PageWritten(nonFungibleTokenId, cid, block.timestamp);

        // If the user has chosen, make the written content public in the AnkyAirdrop contract.
        if(userWantsItToBePublic) {
            ankyAirdrop.registerWriting("notebook", cid);
        }
    }

    /**
     * @dev Function to check if a non-fungible notebook is derived from a specified fungible notebook.
     * @param nonFungibleNotebookId - The ID of the non-fungible notebook.
     * @param originalFungibleId - The ID of the fungible notebook.
     * @return - True if the non-fungible notebook was derived from the specified fungible notebook, false otherwise.
     */
    function isDerivedFromOriginal(uint256 nonFungibleNotebookId, uint256 originalFungibleId) private view returns (bool) {
        return derivedNotebookExists[originalFungibleId][nonFungibleNotebookId];
    }

    /**
     * @dev Function to fetch details of all fungible notebooks.
     * @return ids - Array of fungible notebook IDs.
     * @return creators - Array of creators' addresses for each fungible notebook.
     * @return metadataCIDs - Array of IPFS CIDs for metadata of each fungible notebook.
     * @return originalFungibleNotebookIds - Array indicating the original fungible notebook ID from which each was derived.
     */
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

    /**
     * @dev Function to fetch all non-fungible notebooks derived from a specific fungible notebook.
     * @param nonFungibleNotebookId - The ID of the non-fungible notebook.
     * @return - Array of non-fungible notebook IDs.
     */
    function getAllNotebooksFromSameFungibleNotebook(uint256 nonFungibleNotebookId) public view returns (uint256[] memory) {
        uint256 originalNotebookId = nonFungibleNotebooks[nonFungibleNotebookId].originalFungibleNotebookId;
        return allNonFungibleNotebooksFromFungibleNotebook[originalNotebookId];
    }

    /**
     * @dev Function to view all the pages of a specified non-fungible notebook.
     * @param nonFungibleNotebookId - The ID of the non-fungible notebook.
     * @return - Array of Page structs representing the written pages.
     */
    function viewFullNotebook(uint256 nonFungibleNotebookId) external view returns(Page[] memory) {
        address ankyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        uint256 originalFungibleNotebookId = nonFungibleNotebooks[nonFungibleNotebookId].originalFungibleNotebookId;

        // Ensure that the caller either owns the notebook or it's derived from a fungible notebook they own.
        require(
            balanceOf(ankyAddress, nonFungibleNotebookId) > 0 ||
            isDerivedFromOriginal(nonFungibleNotebookId, originalFungibleNotebookId),
            "You can't access this information."
        );

        return writtenNotebookPages[nonFungibleNotebookId];
    }

    /**
     * @dev Function to get the total number of pages written in a specified non-fungible notebook.
     * @param nonFungibleTokenId - The ID of the non-fungible notebook.
     * @return - The total number of written pages.
     */
    function getTotalPagesWritten(uint256 nonFungibleTokenId) external view returns(uint256) {
        return writtenNotebookPages[nonFungibleTokenId].length;
    }

    /**
     * @dev Function to get all non-fungible notebooks owned by a specified Anky address.
     * @param ankyAddress - The Anky address.
     * @return - Array of non-fungible notebook IDs.
     */
    function getNotebooksOfAnky(address ankyAddress) external view returns(uint256[] memory) {
        return notebooksOwnedByAnky[ankyAddress];
    }

    /**
     * @dev Override of the safeTransferFrom function to add a restriction: prevent the transfer of derived non-fungible notebooks.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public override {
        if(nonFungibleNotebooks[id].creator != address(0)) {  // If ID exists in nonFungibleNotebooks
            require(
                nonFungibleNotebooks[id].originalFungibleNotebookId != 0,
                "Cannot transfer a derived non-fungible notebook."
            );
        }
        super.safeTransferFrom(from, to, id, amount, data);
    }
}
