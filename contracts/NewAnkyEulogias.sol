// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyEulogias is ERC1155, Ownable {

    struct Eulogia {
        uint256 eulogiaId;
        string metadataCID;
        uint256 maxMessages;
        string passwordsCID;
    }

    mapping(uint256 => Eulogia) public eulogias;

    mapping(uint256 => address[]) public eulogiaOwners;
    mapping(address => uint256[]) public userCreatedEulogias;
    mapping(address => uint256[]) public eulogiasWhereUserWrote;
    mapping(address => uint256[]) public userOwnedEulogias;

    IAnkyAirdrop public ankyAirdrop;

    event EulogiaCreated(uint256 indexed eulogiaId, address indexed eulogiaCreator, string metadataCID);
    event EulogiaMinted(uint256 indexed eulogiaId, address indexed newOwner);

    modifier onlyAnkyOwner() {
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "Must own an Anky");
        _;
    }

    constructor(address _ankyAirdrop) ERC1155("") Ownable() {
                ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
    }

    function createEulogia(uint256 randomUID, string memory metadataCID, uint256 maxMsgs, string memory passwordsCID ) external onlyAnkyOwner {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");
        require(maxMsgs <= 500, "Max messages for a Eulogia is 500");

        uint256 newEulogiaId = uint256(bytes32(keccak256(abi.encodePacked(msg.sender, randomUID))));

        eulogias[newEulogiaId] = Eulogia({
            eulogiaId: newEulogiaId,
            metadataCID: metadataCID,
            maxMessages: maxMsgs,
            passwordsCID: passwordsCID
        });

        emit EulogiaCreated(newEulogiaId, usersAnkyAddress, metadataCID);
    }

    function mintEulogia(uint256 eulogiaId) external onlyAnkyOwner {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(_isEulogiaWriter(usersAnkyAddress, eulogiaId), "Only writers of this Eulogia can mint.");

        require(balanceOf(usersAnkyAddress, eulogiaId) == 0, "You already own a copy of this eulogia");

        _mint(usersAnkyAddress, eulogiaId, 1, "");
        eulogiaOwners[eulogiaId].push(usersAnkyAddress);
        userOwnedEulogias[usersAnkyAddress].push(eulogiaId);
        emit EulogiaMinted(eulogiaId, usersAnkyAddress);
    }

    function getEulogia(uint256 eulogiaId) external view returns(Eulogia memory) {
        return eulogias[eulogiaId];
    }

    function getUserCreatedEulogias() external view returns (uint256[] memory) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        return userCreatedEulogias[usersAnkyAddress];
    }

    function getUserWrittenEulogias() external view returns (uint256[] memory) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        return eulogiasWhereUserWrote[usersAnkyAddress];
    }

    function getUserOwnedEulogias() external view returns (uint256[] memory) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        return userOwnedEulogias[usersAnkyAddress];
    }

    function _isEulogiaWriter(address writersAnkyAddress, uint256 eulogiaId) internal view returns (bool) {
        uint256[] memory userWrittenEulogias = eulogiasWhereUserWrote[writersAnkyAddress];
        for(uint256 i = 0; i < userWrittenEulogias.length; i++) {
            if(userWrittenEulogias[i] == eulogiaId) {
                return true;
            }
        }
        return false;
    }
}
