// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyEulogias is ERC1155, Ownable {
    using Counters for Counters.Counter;

    struct Message {
        address writer;
        string whoWroteIt;
        string cid;
        uint256 timestamp;
    }

    struct Eulogia {
        string metadataURI;
        Message[] messages;
        uint256 maxMessages;
        bool isPublic;  // New field
        address[] allowedWriters;
    }

    Counters.Counter private _eulogiaIds;
    mapping(uint256 => Eulogia) public eulogias;
    mapping(address => uint256[]) public userEulogias;
    mapping(address => uint256[]) public writtenEulogias;
    IAnkyAirdrop public ankyAirdrop;

    event EulogiaCreated(uint256 indexed eulogiaId, address indexed owner, string metadataURI);
    event MessageAdded(uint256 indexed eulogiaId, address indexed writer, string cid);

    constructor(address _ankyAirdrop) ERC1155("Anky Eulogias URI {id}.json") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
    }

    function _getUserAnkyAddress() internal view returns (address) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "Invalid Anky address");
        return usersAnkyAddress;
    }

    function createEulogia(string memory metadataURI, uint256 maxMsgs) external {
        require(maxMsgs <= 100, "Max messages for a Eulogia is 100");
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "Address needs to own an Anky to mint a notebook");

        address usersAnkyAddress = _getUserAnkyAddress();
        uint256 newEulogiaId = _eulogiaIds.current();

        eulogias[newEulogiaId].metadataURI = metadataURI;
        eulogias[newEulogiaId].maxMessages = maxMsgs;

        _mint(usersAnkyAddress, newEulogiaId, 1, ""); // Mint 1 token of the given ID
        userEulogias[usersAnkyAddress].push(newEulogiaId);
        emit EulogiaCreated(newEulogiaId, msg.sender, metadataURI);
        _eulogiaIds.increment();
    }

    function writeEulogiaPage(uint256 eulogiaId, string memory cid, string memory whoWroteIt, bool isPublic, bool wantsToMint) external {
        Eulogia storage eulogia = eulogias[eulogiaId];
        require(eulogia.messages.length < eulogia.maxMessages, "Maximum messages reached for this eulogia.");

        Message memory newMessage = Message({
            writer: msg.sender,
            whoWroteIt: whoWroteIt,
            cid: cid,
            timestamp: block.timestamp
        });

        eulogia.messages.push(newMessage);
        writtenEulogias[msg.sender].push(eulogiaId);
        emit MessageAdded(eulogiaId, msg.sender, cid);

        if(isPublic){
            ankyAirdrop.registerWriting("eulogia", cid);
        }

        if (wantsToMint) {
            _mintEulogiaNFT(eulogiaId);
        }
    }

    function _mintEulogiaNFT(uint256 eulogiaId) internal {
        address usersAnkyAddress = _getUserAnkyAddress();
        require(_isEulogiaWriter(usersAnkyAddress, eulogiaId), "Only writers of this Eulogia can mint.");
        _mint(usersAnkyAddress, eulogiaId, 1, ""); // Mint 1 token of the given ID
    }

    function getAllMessages(uint256 eulogiaId) external view returns(Message[] memory) {
        address usersAnkyAddress = _getUserAnkyAddress();
        require(_isEulogiaWriter(usersAnkyAddress, eulogiaId), "Only writers of this Eulogia can view messages.");
        return eulogias[eulogiaId].messages;
    }

    function getPublicEulogias() external view returns (uint256[] memory) {
        uint256[] memory publicEulogiaIds = new uint256[](_eulogiaIds.current());
        uint256 counter = 0;

        for (uint256 i = 0; i < _eulogiaIds.current(); i++) {
            if (eulogias[i].isPublic) {
                publicEulogiaIds[counter] = i;
                counter++;
            }
        }

        // Trim the array to the correct size
        uint256[] memory trimmedPublicEulogiaIds = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            trimmedPublicEulogiaIds[i] = publicEulogiaIds[i];
        }

        return trimmedPublicEulogiaIds;
    }

    function getEulogia(uint256 eulogiaId) external view returns(Eulogia memory) {
        return eulogias[eulogiaId];
    }

    // function allowWriter(uint256 eulogiaId, address writer) external {
    //     Eulogia storage eulogia = eulogias[eulogiaId];
    //     require(ownerOf(eulogiaId) == _getUserAnkyAddress(), "Only the owner of this eulogia can allow writers.");

    //     eulogia.allowedWriters.push(writer);
    // }

    function getUserEulogias() external view returns (uint256[] memory) {
        return userEulogias[_getUserAnkyAddress()];
    }

    function getWrittenEulogias() external view returns (uint256[] memory) {
        return writtenEulogias[_getUserAnkyAddress()];
    }

    function mintEulogiaToAnky(uint256 eulogiaId) external {
        address usersAnkyAddress = _getUserAnkyAddress();
        require(_isEulogiaWriter(usersAnkyAddress, eulogiaId), "Only writers of this Eulogia can mint.");
        _mint(usersAnkyAddress, eulogiaId, 1, ""); // Mint 1 token of the given ID
    }

    function _isEulogiaWriter(address writersAnkyAddress, uint256 eulogiaId) internal view returns (bool) {
        uint256[] memory userWrittenEulogias = writtenEulogias[writersAnkyAddress];
        for(uint256 i = 0; i < userWrittenEulogias.length; i++) {
            if(userWrittenEulogias[i] == eulogiaId) {
                return true;
            }
        }
        return false;
    }
}
