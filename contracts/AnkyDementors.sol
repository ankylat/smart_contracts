// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyDementor is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _dementorIds;

    uint256 public dementorPrice;

    struct Dementor {
        uint256 dementorId;
        string firstPageCid;
    }

    mapping(uint256 => Dementor) public dementors;

    mapping(address => uint256[]) public userDementorIds;

    IAnkyAirdrop public ankyAirdrop;

    event DementorCreated(uint256 indexed dementorId, address indexed owner);

    modifier onlyAnkyOwner() {
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "Must own an Anky");
        _;
    }

    constructor(address _ankyAirdrop) ERC721("AnkyDementor", "AD") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
        dementorPrice = 0.0001 ether;
    }

    function mintDementor(address mintTo, string memory firstPageCid) external payable {
        require(mintTo == msg.sender, "The sender needs to be the address where this dementor will go");
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(mintTo);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        _dementorIds.increment();
        uint256 newDementorId = _dementorIds.current();

        Dementor storage dementor = dementors[newDementorId];
        dementor.dementorId = newDementorId;
        dementor.firstPageCid = firstPageCid;

        _mint(usersAnkyAddress, newDementorId);
        userDementorIds[usersAnkyAddress].push(newDementorId);

        emit DementorCreated(newDementorId, usersAnkyAddress);
    }

    function getDementor(uint256 dementorId) external view returns (Dementor memory) {
        require(_exists(dementorId), "Invalid tokenId");
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(ownerOf(dementorId) == usersAnkyAddress, "Not the owner of this journal");
        return dementors[dementorId];
    }

    function getUserDementors() external view returns (uint256[] memory) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        return userDementorIds[usersAnkyAddress];
    }


    function setDementorPrice(uint256 _price) external onlyOwner {
        dementorPrice = _price;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
