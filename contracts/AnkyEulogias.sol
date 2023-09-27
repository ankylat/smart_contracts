// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyEulogias is ERC721Enumerable, Ownable {
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
    }

    Counters.Counter private _eulogiaIds;
    mapping(uint256 => Eulogia) public eulogias;
    mapping(address => uint256[]) public userEulogias;
    mapping(address => uint256[]) public writtenEulogias;
    IAnkyAirdrop public ankyAirdrop;

    event EulogiaCreated(uint256 indexed eulogiaId, address indexed owner, string metadataURI);
    event MessageAdded(uint256 indexed eulogiaId, address indexed writer, string cid);

    constructor(address _ankyAirdrop) ERC721("Anky Eulogias", "ANKYMEM") {
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

        _mint(usersAnkyAddress, newEulogiaId);
        userEulogias[usersAnkyAddress].push(newEulogiaId);
        emit EulogiaCreated(newEulogiaId, msg.sender, metadataURI);
        _eulogiaIds.increment();
    }

    function addMessage(uint256 eulogiaId, string memory cid, string memory whoWroteIt) external {
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
    }

    function getAllMessages(uint256 eulogiaId) external view returns(Message[] memory) {
        address usersAnkyAddress = _getUserAnkyAddress();
        require(_isEulogiaWriter(usersAnkyAddress, eulogiaId), "Only writers of this Eulogia can view messages.");
        return eulogias[eulogiaId].messages;
    }

    function getEulogia(uint256 eulogiaId) external view returns(Eulogia memory) {
        return eulogias[eulogiaId];
    }

    function getUserEulogias() external view returns (uint256[] memory) {
        return userEulogias[_getUserAnkyAddress()];
    }

    function getWrittenEulogias() external view returns (uint256[] memory) {
        return writtenEulogias[_getUserAnkyAddress()];
    }

    function mintEulogiaToAnky(uint256 eulogiaId) external {
        address usersAnkyAddress = _getUserAnkyAddress();
        require(_isEulogiaWriter(usersAnkyAddress, eulogiaId), "Only writers of this Eulogia can mint.");
        _mint(usersAnkyAddress, eulogiaId);
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
