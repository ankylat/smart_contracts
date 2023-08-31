// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract AnkyAirdrop is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Mapping from token ID to metadata URI
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("AnkyAirdrop", "ANKY") {}

    // Function to airdrop a single NFT to a given address
    function airdropNft(address recipient) public onlyOwner {
        require(balanceOf(recipient) == 0, "Address already owns an Anky");
        uint256 newTokenId = _tokenIds.current();
        _safeMint(recipient, newTokenId);
        _tokenIds.increment();
    }

    // Function to set or update the token URI
    function setTokenURI(uint256 tokenId, string memory newUri) public {
        require(_exists(tokenId), "Token ID does not exist");
        require(ownerOf(tokenId) == msg.sender, "Only the owner can update the URI");
        _setTokenURI(tokenId, newUri);
    }

    // Function to retrieve the token URI
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist");
        return tokenURI(tokenId);
    }
}
