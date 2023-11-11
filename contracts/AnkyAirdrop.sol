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


    constructor(address _registry, address _implementation) ERC721("AnkyAirdrop", "ANKY") {
        //This line allows this contract to interact with the registry contract.
        registry = IERC6551Registry(_registry);
        _implementationAddress = _implementation;
    }


    function mintTo(address _to) public payable returns (uint256) {
        require(_tokenIds.current() < 97, "There is no more supply of Anky Dementors");
        require(msg.value == 0.024 ether, "This NFT costs around 50 usd, there are 96 of them.");
        require(balanceOf(_to) == 0, "You already own an Anky");
        uint256 newAnkyId = _tokenIds.current();
        _safeMint(_to, newAnkyId);
        _tokenIds.increment();

        address tba = registry.createAccount(
            _implementationAddress,
            block.chainid,
            address(this),
            newAnkyId,
            0,       // salt
            bytes("") // initData
        );

        ownerToTBA[_to] = tba;
        tbaToAnkyIndex[tba] = newAnkyId;

        emit TBACreated(_to, tba, newAnkyId);

        // **** Now i need to send ether to eth mainnet to mint an anky genesis NFT ****
        // **** Here, we should programatically bridge 0.01618 + gas to ETHEREUM MAINNET, and with that trigger the mint function of this smart contract on ETHEREUM MAINNET: 0x5806485215c8542c448ecf707ab6321b948cab90, sending that NFT to _to on ETHEREUM MAINNET.
        // **** The rest of the funds that were not used to buy the Anky Genesis NFT need to be sent back to the users wallet on base (on this exact mintTo function)


        return newAnkyId;
    }

    function airdropToAnkyGenesisHolders(address _to) public payable onlyOwner returns (uint256) {
        require(_tokenIds.current() < 25, "There is no more supply of Anky Dementors");
        require(balanceOf(_to) == 0, "You already own an Anky");
        uint256 newAnkyId = _tokenIds.current();
        _safeMint(_to, newAnkyId);
        _tokenIds.increment();

        address tba = registry.createAccount(
            _implementationAddress,
            block.chainid,
            address(this),
            newAnkyId,
            0,       // salt
            bytes("") // initData
        );

        ownerToTBA[_to] = tba;
        tbaToAnkyIndex[tba] = newAnkyId;

        emit TBACreated(_to, tba, newAnkyId);

        return newAnkyId;
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
