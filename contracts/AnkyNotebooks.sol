// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the OpenZeppelin ERC721 contract and other required utilities
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AnkyNotebooks is ERC721Enumerable, Ownable {
    // Counter for keeping track of the last minted token ID
    uint256 private _lastMinted = 1;
    mapping(PageCount => uint256) public mintingPrice;

    // Enumeration to define different types of Page Counts
    enum PageCount { EIGHT, TWENTY_FOUR, NINETY_SIX }

    // Struct to represent a Notebook with different Page Counts and URLs
    struct Notebook {
        PageCount pageCount;
        mapping(uint256 => string) pageUrls;
    }

    // Mapping to keep track of all minted Notebooks
    mapping(uint256 => Notebook) public notebooks;

    // Constructor to initialize contract with a name and symbol
    constructor() ERC721("AnkyNotebooks", "ANKYNO") {
        mintingPrice[PageCount.EIGHT] = 0.00008 ether;
        mintingPrice[PageCount.TWENTY_FOUR] = 0.00024 ether;
        mintingPrice[PageCount.NINETY_SIX] = 0.00096 ether;
    }

    // Function to mint new Notebooks
    function mintNotebook(address recipient, PageCount pageCount) public payable returns (uint256) {
        // Check if the sent ETH is sufficient for the chosen Notebook type
        require(recipient == msg.sender, "You are trying to mint for a different address");
        require(msg.value >= mintingPrice[pageCount], "Insufficient ETH sent for the chosen notebook type.");


        // Mint the token to the sender
        _mint(recipient, _lastMinted);

        // Initialize the Notebook
        notebooks[_lastMinted].pageCount = pageCount;

        // Populate the default page URLs
        for (uint256 i = 1; i <= uint256(pageCount); i++) {
            notebooks[_lastMinted].pageUrls[i] = "https://default.url/";
        }

        // Increment the counter for the next token
        _lastMinted++;

        // Calculate 80% of the minting fee
        uint256 refundAmount = (msg.value * 8) / 10;

        // Transfer 80% of the minting fee back to the user
        payable(msg.sender).transfer(refundAmount);

        // Return the newly minted token ID
        return _lastMinted - 1;
    }

    // Function to update Notebook metadata (page URLs)
    function updateMetadata(uint256 tokenId, uint256 pageNumber, string memory newUrl) public {
        // Check if the Notebook exists
        require(_exists(tokenId), "Notebook does not exist.");
        // Check if the message sender is the owner of the Notebook
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this notebook.");
        // Check if the page number is valid
        require(pageNumber <= uint256(notebooks[tokenId].pageCount), "Invalid page number.");
        // Update the page URL
        notebooks[tokenId].pageUrls[pageNumber] = newUrl;
    }

     function getCompleteNotebook(uint256 tokenId) public view returns (tokenId unit256 ) {
        // VERY IMPORTANT: ONLY THE ADDRESS THAT OWNS THE NOTEBOOK CAN CALL THIS FUNCTION
        require(msg.sender == ownerOf(tokenId), "You are not the owner of this notebook");
        require(_exists(tokenId), "Notebook does not exist.");
        return notebooks[tokenId];
     }

    function getNotebookPage(uint256 tokenId, uint256 pageNumber) public view returns (string memory) {
        // VERY IMPORTANT: ONLY THE ADDRESS THAT OWNS THE NOTEBOOK CAN CALL THIS FUNCTION
        require(msg.sender != ownerOf(tokenId), "You are not the owner of this notebook");

        require(_exists(tokenId), "Notebook does not exist.");
        require(pageNumber <= uint256(notebooks[tokenId].pageCount), "Invalid page number.");
        return notebooks[tokenId].pageUrls[pageNumber];
    }

    function getOwnedNotebooks(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 i = 0; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(owner, i);
            }
            return result;
        }
    }
}
