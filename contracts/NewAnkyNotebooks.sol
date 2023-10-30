// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyNotebooks is ERC1155, Ownable {

    struct Notebook {
        uint256 notebookId;
        string metadataCID;
        uint256 supply;
        uint256 price;
    }

    mapping(uint256 => Notebook) public notebooks;

    mapping(address => uint256[]) public userOwnedNotebookIds;
    mapping(address => uint256[]) public userCreatedNotebooksByIds;
    mapping(uint256 => address[]) public ownersOfNotebook;
    mapping(address => mapping(uint256 => string)) public userNotebookPasswords;

    IAnkyAirdrop public ankyAirdrop;

    event NotebookCreated(uint256 notebookId, address indexed notebookCreator, string metadataCID);
    event NotebookMinted(uint256 indexed notebookId, address indexed newOwner, string metadataCID);

    modifier onlyAnkyOwner() {
        require(ankyAirdrop.balanceOf(msg.sender) != 0, "Must own an Anky");
        _;
    }

    modifier onlyNotebookOwner(uint256 notebookId) {
        address thisUsersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(balanceOf(thisUsersAnkyAddress, notebookId) > 0, "Only if you own one of these notebooks you can do this");
        _;
    }

    constructor(address _ankyAirdrop) ERC1155("") Ownable() {
                ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);
    }


    function createNotebook(uint256 randomUID, string memory metadataCID, uint256  supply, uint256  price) external onlyAnkyOwner {
        // here it would be amazing to have the user spend mana to craete a notebook
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        uint32 newNotebookId = uint32(bytes4(keccak256(abi.encodePacked(msg.sender, randomUID))));

        notebooks[newNotebookId] = Notebook({
            notebookId: newNotebookId,
            metadataCID: metadataCID,
            supply: supply,
            price: price
        });

        userCreatedNotebooksByIds[usersAnkyAddress].push(newNotebookId);
        emit NotebookCreated(newNotebookId, usersAnkyAddress, metadataCID);
    }

   function mintNotebook(uint256 notebookId, uint256 amount, string memory passwordsCID) external payable onlyAnkyOwner {
        Notebook memory thisNotebook = notebooks[notebookId];

        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(amount == 1, "You can mint only one notebook at a time");

        // Check supply constraints
        uint256 currentSupply = thisNotebook.supply;
        require(currentSupply >= amount, "Insufficient supply");

        uint256 totalPrice = thisNotebook.price * amount;
        require(msg.value >= totalPrice, "Insufficient Ether sent");
        _mint(usersAnkyAddress, notebookId, amount, "");
        notebooks[notebookId].supply = notebooks[notebookId].supply -1;
        userOwnedNotebookIds[usersAnkyAddress].push(notebookId);
        userNotebookPasswords[usersAnkyAddress][notebookId] = passwordsCID;

        emit NotebookMinted(notebookId, usersAnkyAddress, thisNotebook.metadataCID);
    }

    function getPasswordCID(uint256 notebookId) external view returns (string memory) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");
        require(balanceOf(usersAnkyAddress, notebookId) > 0, "You dont own one of these notebooks");
        return userNotebookPasswords[usersAnkyAddress][notebookId];
    }

    function getNotebook(uint256 notebookId) external view onlyNotebookOwner(notebookId) returns(Notebook memory)  {
        return notebooks[notebookId];
    }

    function getUserNotebooks() external view returns(uint256[] memory) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");
        return userOwnedNotebookIds[usersAnkyAddress];
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
