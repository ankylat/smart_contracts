// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IRecovery.sol";

contract AnkyAirdrop is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    uint256 private _tokenIds;

    // This is the interface for interacting with the registry and creating the TBA from this contract.
    IERC6551Registry public registry;

    // This is the first argument to the registry function to create the TBA (token bound account)
    address public _implementationAddress;
    string private _baseTokenURI;

    // Mapping for storing the address of the TBA (token bound account) associated with the address that owns that anky
    mapping(address => address) public ownerToTBA;
    mapping(address => uint256) public tbaToAnkyIndex;

    // EVENTS
    event TBACreated(address indexed user, address indexed tbaAddress, uint256 indexed tokenId);
    event WritingEvent(
        uint256 indexed ankyTokenId,
        string writingContainerType,
        string cid,
        uint256 timestamp
    );

    constructor(address _registry, address _implementation, string memory _baseUriString) ERC721("AnkyAirdrop", "ANKYS1") {
        //This line allows this contract to interact with the registry contract.
        registry = IERC6551Registry(_registry);
        _implementationAddress = _implementation;
        _baseTokenURI = _baseUriString;
        _tokenIds++;
    }

    function mintTo(address _to) public payable returns (uint256) {
        require(_tokenIds < 97, "There is no more supply of Anky Dementors");
        require(balanceOf(_to) == 0, "You already own an Anky");
        uint256 newAnkyId = _tokenIds++;
        _safeMint(_to, newAnkyId);

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

    function airdropToAnkyGenesisHolders(address _to) public payable onlyOwner returns (uint256) {
        require(_tokenIds < 23, "There is no more supply of Anky Dementors");
        require(balanceOf(_to) == 0, "You already own an Anky");
        uint256 newAnkyId = _tokenIds++;
        _safeMint(_to, newAnkyId);

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


            // Function to set or update the token URI by the token owner
    function setTokenURI(uint256 tokenId, string memory newUri) public {
        require(ERC721._exists(tokenId), "Token ID does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner");
        _setTokenURI(tokenId, newUri);
    }

    // Function to delete the token URI by the contract owner
    function deleteTokenURI(uint256 tokenId) public onlyOwner {
        require(ERC721._exists(tokenId), "Token ID does not exist");
        _setTokenURI(tokenId, "");
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
    
    // Function to recover the TBA after a period of inactivity
    function recoverTBA(uint256 tokenId) public {
        address tba = getTBA(tokenId);
        
        (uint lastTimeSeen, uint recoverAfter, address beneficiary) = IRecovery(
            tba
        ).recoveryInfo();
        
        require(block.timestamp - lastTimeSeen > recoverAfter, "Cannot recover an active account");
        
        safeTransferFrom(ownerOf(tokenId), beneficiary, tokenId);
    }

    // Function to get the TBA address of the token that the calling address owns
    function getUsersAnkyAddress(address userWallet) public view returns (address) {
        //require(balanceOf(userWallet) > 0, "You don't own an Anky");
        // view functions should not revert but return the ZeroAddress
        return ownerToTBA[userWallet];
    }

    // Function to retrieve the token URI
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        //require(ERC721._exists(tokenId), "Token ID does not exist");
        // tokenUri performs the same check
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

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        //require(ERC721._exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        // view functions must not revert but return the empty string
        // Concatenate the base URI with the token ID if the token exists
        return ERC721._exists(tokenId) ? string(
            abi.encodePacked(_baseTokenURI, Strings.toString(tokenId))
        ) : "";
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
