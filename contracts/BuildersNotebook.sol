// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BuildersNotebook is ERC721, Ownable {
    using Strings for string;
    // Array to store URLs of writings
    string[] public writings;
    uint256 public notebookId = 0;

    constructor() ERC721("BuildersNotebook", "BDNB") {}

    function safeMint(string memory url, address to) public  {
        writings.push(url); // Add the writing's URL to the array
        _mint(to, notebookId); // Mint the NFT with the next tokenId to the wallet of the anky of the user
        notebookId++;
    }

    /**
     * Retrieve the URL of a writing for a given index
     *
     * @param index - Index of the writing
     * @return string - URL of the writing
     */
    function getWriting(uint256 index) public view returns (string memory) {
        require(index < writings.length, "Index out of bounds");
        return writings[index];
    }

    /**
     * Get the total number of writings stored
     *
     * @return uint256 - Total number of writings
     */
    function getTotalWritings() public view returns (uint256) {
        return writings.length;
    }


    function getAllWritings() public view returns (string[] memory) {
        return writings;
    }
}
