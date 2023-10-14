// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./interfaces/IERC6551Registry.sol";

contract AnkyAirdrop is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // This is the interface for interacting with the registry and creating the TBA from this contract.
    IERC6551Registry public registry;

    // This is the first argument to the registry function to create the TBA (token bound account)
    address public _implementationAddress;
    address private ankyNotebooksAddress;
    address private ankyEulogiasAddress;
    address private ankyJournalsAddress;

    // Mapping for storing the address of the TBA (token bound account) associated with the address that owns that anky
    mapping(address => address) public ownerToTBA;
    mapping(address => uint256) private tbaToAnkyIndex;

    // EVENTS
    event TBACreated(address indexed user, address indexed tbaAddress, uint256 indexed tokenId);
    event WritingEvent(
        uint256 indexed ankyTokenId,
        string writingContainerType,
        string cid,
        uint256 timestamp
    );

    modifier onlyAllowedContracts() {
        require(msg.sender == ankyNotebooksAddress || msg.sender == ankyEulogiasAddress || msg.sender == ankyJournalsAddress, "Not allowed");
        _;
    }

    constructor(address _registry, address _implementation) ERC721("AnkyAirdrop", "ANKY") {
        //This line allows this contract to interact with the registry contract.
        registry = IERC6551Registry(_registry);
        _implementationAddress = _implementation;
    }

    // Function to airdrop a single NFT to a given address callWithSyncFee
    function airdropNft(address to) public returns(uint256, string memory) {
        // Add a check that needs a password or something.
        require(balanceOf(to) == 0, "Address already owns an Anky");
        uint256 newTokenId = _tokenIds.current();
        _safeMint(to, newTokenId);
        _tokenIds.increment();

        string memory newTokenUri = tokenURI(newTokenId);

        return (newTokenId, newTokenUri);
    }

    function setAllowedContracts(address notebooks, address eulogias, address journals) external onlyOwner {
        ankyNotebooksAddress = notebooks;
        ankyEulogiasAddress = eulogias;
        ankyJournalsAddress = journals;
    }

    // Function to create a TBA for a user's Anky callWithSyncFee from gelato (this one doesnt )
    function createTBAforUsersAnky(address userWallet) public returns(address) {
        require(balanceOf(userWallet) != 0, "You don't own an Anky");
        require(ownerToTBA[userWallet] == address(0), "TBA already created for this Anky");

        uint256 tokenId = tokenOfOwnerByIndex(userWallet, 0); // Retrieve token ID of user's Anky

        address tba = registry.createAccount(
            _implementationAddress,
            block.chainid,
            address(this),
            tokenId,
            0,       // salt
            bytes("") // initData
        );

        ownerToTBA[userWallet] = tba;
        tbaToAnkyIndex[tba] = tokenId;

        emit TBACreated(userWallet, tba, tokenId);

        return tba;
    }

    // Function to get the TBA address from the Registry by tokenId
    function getTBA(uint256 tokenId) public view returns (address) {
        return registry.account(
            _implementationAddress,
            block.chainid,
            address(this),
            tokenId,
            0 // salt
        );
    }

   // Function to get the TBA address of the token that the calling address owns
    function getUsersAnkyAddress(address userWallet) public view returns (address) {
        require(balanceOf(userWallet) > 0, "You don't own an Anky");
        return ownerToTBA[userWallet];
    }

    function registerWriting(address usersAnkyAddress, string memory writingContainerType, string memory cid) external onlyAllowedContracts returns (bool) {
        uint256 ankyTokenId = tbaToAnkyIndex[usersAnkyAddress]; // Retrieve token ID of user's Anky

        emit WritingEvent(ankyTokenId, writingContainerType, cid, block.timestamp);

        return true;
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
