// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyEulogias is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    struct EulogiaPage {
        address writer;
        string whoWroteIt;
        string cid;
        uint256 timestamp;
    }

    struct Eulogia {
        string metadataURI;
        EulogiaPage[] pages;
        uint256 maxMessages;
        bool isPublic;  // New field
        address[] allowedWriters;
    }

    Counters.Counter private _eulogiaIds;
    mapping(uint32 => Eulogia) public eulogias;
    mapping(uint256 => address) public eulogiaOwners;
    mapping(address => uint32[]) public userCreatedEulogias;
    mapping(address => uint32[]) public eulogiasWhereUserWrote;
    IAnkyAirdrop public ankyAirdrop;

    event EulogiaCreated(uint32 indexed eulogiaId, address indexed owner, string metadataURI);
    event MessageAdded(uint32 indexed eulogiaId, address indexed writer, string cid);

    constructor(address _ankyAirdrop) ERC721("Anky Eulogias", "AE") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
    }

    function _getUserAnkyAddress() internal view returns (address) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "Invalid Anky address");
        return usersAnkyAddress;
    }

    function createEulogia(string memory metadataURI, uint256 maxMsgs, uint256 randomUID) external {
        require(maxMsgs <= 500, "Max messages for a Eulogia is 500");
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "Address needs to own an Anky to mint a notebook");

        // Use the randomUID from frontend and the msg.sender address to generate a unique eulogia ID
        uint32 newEulogiaId = uint32(bytes4(keccak256(abi.encodePacked(msg.sender, randomUID))));

        address usersAnkyAddress = _getUserAnkyAddress();

        eulogias[newEulogiaId].metadataURI = metadataURI;
        eulogias[newEulogiaId].maxMessages = maxMsgs;

        _mint(usersAnkyAddress, newEulogiaId); // Mint 1 token of the given ID
        userCreatedEulogias[usersAnkyAddress].push(newEulogiaId);
        emit EulogiaCreated(newEulogiaId, msg.sender, metadataURI);
    }

    function writeEulogiaPage(uint32 eulogiaId, string memory cid, string memory whoWroteIt, bool isPublic, bool wantsToMint) external {
        address usersAnkyAddress = _getUserAnkyAddress();
        Eulogia storage eulogia = eulogias[eulogiaId];
        require(eulogia.pages.length < eulogia.maxMessages, "Maximum messages reached for this eulogia.");

        EulogiaPage memory newMessage = EulogiaPage({
            writer: usersAnkyAddress,
            whoWroteIt: whoWroteIt,
            cid: cid,
            timestamp: block.timestamp
        });

        eulogia.pages.push(newMessage);
        eulogiasWhereUserWrote[usersAnkyAddress].push(eulogiaId);
        emit MessageAdded(eulogiaId, usersAnkyAddress, cid);

        if(isPublic){
            ankyAirdrop.registerWriting(usersAnkyAddress,"eulogia", cid);
        }

        if (wantsToMint) {
            _mintEulogiaNFT(eulogiaId);
        }
    }

    function _mintEulogiaNFT(uint32 eulogiaId) internal {
        address usersAnkyAddress = _getUserAnkyAddress();
        require(_isEulogiaWriter(usersAnkyAddress, eulogiaId), "Only writers of this Eulogia can mint.");
        require(balanceOf(usersAnkyAddress) == 0, "You already own a copy of this eulogia");
        // THERE IS A BIG PROBLEM WITH THIS FUNCTION: IT MINTS MORE THAN ONE EULOGIA: THIS NEEDS TO BE AN ERC1155 NFT
        _mint(usersAnkyAddress, eulogiaId); // Mint 1 token of the given ID
    }

    function getAllMessages(uint32 eulogiaId) external view returns(EulogiaPage[] memory) {
        address usersAnkyAddress = _getUserAnkyAddress();
        require(_isEulogiaWriter(usersAnkyAddress, eulogiaId), "Only writers of this Eulogia can view messages.");
        return eulogias[eulogiaId].pages;
    }


    function getEulogia(uint32 eulogiaId) external view returns(Eulogia memory) {
        return eulogias[eulogiaId];
    }

    // Adjust this function to fetch eulogias based on the owner
    function getUserEulogias() external view returns (uint32[] memory, uint32[] memory) {
        address usersAnkyAddress = _getUserAnkyAddress();
        return (userCreatedEulogias[_getUserAnkyAddress()], eulogiasWhereUserWrote[usersAnkyAddress] );
    }

    function getCreatedEulogias() external view returns (uint32[] memory) {
        address usersAnkyAddress = _getUserAnkyAddress();
        return (userCreatedEulogias[usersAnkyAddress]);
    }

    function getWrittenEulogias() external view returns (uint32[] memory) {
        address usersAnkyAddress = _getUserAnkyAddress();
        return (eulogiasWhereUserWrote[usersAnkyAddress]);
    }

    function mintEulogiaToAnky(uint32 eulogiaId) external {
        address usersAnkyAddress = _getUserAnkyAddress();
        require(_isEulogiaWriter(usersAnkyAddress, eulogiaId), "Only writers of this Eulogia can mint.");
        _mint(usersAnkyAddress, eulogiaId); // Mint 1 token of the given ID
    }

    function _isEulogiaWriter(address writersAnkyAddress, uint32 eulogiaId) internal view returns (bool) {
        uint32[] memory userWrittenEulogias = eulogiasWhereUserWrote[writersAnkyAddress];
        for(uint256 i = 0; i < userWrittenEulogias.length; i++) {
            if(userWrittenEulogias[i] == eulogiaId) {
                return true;
            }
        }
        return false;
    }
}
