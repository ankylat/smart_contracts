// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";

// The AnkyEulogials are minted especifically by users in order to be able to invite other people to write on this notebook. It is intended for celebrations such as birthdays, or for mourning when someone dies.
contract AnkyEulogias is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    struct Message {
        address writer;
        string whoWroteIt;
        string cid; // This CID points to the actual content on Arweave
        uint256 timestamp;
    }

    struct Eulogia {
        string metadataURI;
        bytes32 passwordHash;
        uint256 messageCount;
        uint256 maxMessages;
    }

    Counters.Counter private _eulogiaIds;
    mapping(uint256 => Eulogia) public eulogias;
    mapping(uint256 => mapping(uint256 => Message)) public eulogiaMessages;
    IAnkyAirdrop public ankyAirdrop;

    event EulogiaCreated(uint256 indexed eulogiaId, address indexed owner, string metadataURI);
    event MessageAdded(uint256 indexed eulogiaId, address indexed writer, string cid);

    constructor(address _ankyAirdrop) ERC721("Anky Eulogias", "ANKYMEM") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
    }

    function createEulogia(string memory metadataURI, string memory password, uint256 maxMsgs) external {
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "Address needs to own an Anky to mint a notebook");
        address tbaAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(tbaAddress != address(0), "Invalid Anky address");

        uint256 newEulogiaId = _eulogiaIds.current();

        bytes32 passwordHash = keccak256(abi.encodePacked(password));
        eulogias[newEulogiaId] = Eulogia({
            metadataURI: metadataURI,
            passwordHash: passwordHash,
            messageCount: 0, // Initialize with zero messages
            maxMessages: maxMsgs
        });

        _mint(tbaAddress, newEulogiaId);
        emit EulogiaCreated(newEulogiaId, msg.sender, metadataURI);
        _eulogiaIds.increment();
    }

    function addMessage(uint256 eulogiaId, string memory password, string memory cid, string memory whoWroteIt) external {
        require(isValidPassword(eulogiaId, password), "Invalid password");

        Eulogia storage eulogia = eulogias[eulogiaId];
        require(eulogia.messageCount < eulogia.maxMessages, "Maximum messages reached for this eulogia.");

        Message memory newMessage = Message({
            writer: msg.sender,
            whoWroteIt: whoWroteIt,
            cid: cid,
            timestamp: block.timestamp
        });

        eulogiaMessages[eulogiaId][eulogia.messageCount] = newMessage;
        eulogia.messageCount++;

        emit MessageAdded(eulogiaId, msg.sender, cid);
    }

    function getAllMessages(uint256 eulogiaId) external view returns(Message[] memory) {
        Message[] memory messages = new Message[](eulogias[eulogiaId].messageCount);

        for(uint256 i = 0; i < eulogias[eulogiaId].messageCount; i++) {
            messages[i] = eulogiaMessages[eulogiaId][i];
        }

        return messages;
    }

    function getEulogia(uint256 eulogiaId) external view returns(Eulogia memory) {
        return eulogias[eulogiaId];
    }

    function isValidPassword(uint256 eulogiaId, string memory password) public view returns(bool) {
        bytes32 providedHash = keccak256(abi.encodePacked(password));
        return providedHash == eulogias[eulogiaId].passwordHash;
    }

    function mintEulogiaToAnky(uint256 eulogiaId) external {
        address tbaAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(tbaAddress != address(0), "Invalid Anky address");

        _mint(tbaAddress, eulogiaId);
    }
}
