// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./interfaces/IERC6551Registry.sol";

contract AnkyAirdrop is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // I'm not sure how this works.
    IERC6551Registry public registry;

    // This is the first argument to the registry function to create the TBA (token bound account)
    address private _implementationAddress;

    // Mapping from token ID to metadata URI
    mapping(uint256 => string) private _tokenURIs;
    // Mapping for storing the address of the TBA (token bound account) associated with this token
    mapping(uint256 => address) public tokenToTBA;

    constructor(address _registry, address _implementation) ERC721("AnkyAirdrop", "ANKY") {
        //This line allows this contract to interact with the registry contract.
        registry = IERC6551Registry(_registry);
        _implementationAddress = _implementation;
    }

    // Function to airdrop a single NFT to a given address
    function airdropNft(address recipient) public onlyOwner {
        require(balanceOf(recipient) == 0, "Address already owns an Anky");
        uint256 newTokenId = _tokenIds.current();
        // Here there needs to be a call to the registry to transform this anky into an erc6551 TBA.
        _safeMint(recipient, newTokenId);
        // Create the TBA for this user.

       address tba = registry.createAccount(
            _implementationAddress,  // implementation
            block.chainid,  // chainId
            address(this),  // tokenContract
            newTokenId,  // tokenId
            0,  // salt or seed
            "0x" // initData, assuming no initialization data
        );

        tokenToTBA[newTokenId] = tba;
        _tokenIds.increment();
    }

    // Function to get the TBA address of a given tokenId
    function getTBAOfToken(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Token ID does not exist");
        return tokenToTBA[tokenId];
    }

    // Function to get the TBA address of the token that the calling address owns
    function getMyAnkyAddress() public view returns (address) {
        uint256 myTokenId = tokenOfOwnerByIndex(msg.sender, 0); // As each account owns one and only one Anky
        require(myTokenId != 0, "You don't own your Anky... yet. It is time to fix that");
        return tokenToTBA[myTokenId];
    }

    // Function to set or update the token URI, only the owner of the contract (anky server) can update the metadata
    function setTokenURI(uint256 tokenId, string memory newUri) public onlyOwner {
        require(_exists(tokenId), "Token ID does not exist");
        _setTokenURI(tokenId, newUri);
    }

    // Function to retrieve the token URI
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist");
        return tokenURI(tokenId);
    }

     // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
