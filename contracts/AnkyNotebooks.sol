// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./interfaces/AnkyAirdrop.sol";

contract AnkyNotebooks is ERC1155, Ownable, ERC1155Supply {
    using Counters for Counters.Counter;
    Counters.Counter private _notebookIds;

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

    function createNotebook(string memory metadataCID, uint256 supply, uint256 price) external  {
        // here it would be amazing to have the user spend mana to craete a notebook
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        _notebookIds.increment();
        uint256 newNotebookId = _notebookIds.current();

        notebooks[newNotebookId] = Notebook({
            notebookId: newNotebookId,
            metadataCID: metadataCID,
            supply: supply - 1,
            price: price
        });

        userCreatedNotebooksByIds[usersAnkyAddress].push(newNotebookId);

        _mint(usersAnkyAddress, newNotebookId, 1, "");
        userOwnedNotebookIds[usersAnkyAddress].push(newNotebookId);

        emit NotebookCreated(newNotebookId, usersAnkyAddress, metadataCID);
        emit NotebookMinted(newNotebookId, usersAnkyAddress, metadataCID);
    }

    // i added the mintTo parameter to be able to use crossmint.
   function mintNotebook(address mintTo, uint256 notebookId, uint256 amount) external payable {
        Notebook memory thisNotebook = notebooks[notebookId];

        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(mintTo);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");

        require(amount == 1, "You can mint only one notebook at a time");

        // Check supply constraints
        uint256 currentSupply = thisNotebook.supply;
        require(currentSupply >= amount, "This notebook is sold out");

        require(msg.value >= thisNotebook.price, "Insufficient Ether sent to pay for this notebook");
        _mint(usersAnkyAddress, notebookId, 1, "");
        notebooks[notebookId].supply = notebooks[notebookId].supply -1;
        userOwnedNotebookIds[usersAnkyAddress].push(notebookId);
        ownersOfNotebook[notebookId].push(usersAnkyAddress);

        emit NotebookMinted(notebookId, usersAnkyAddress, thisNotebook.metadataCID);
    }

    function getNotebook(uint256 notebookId) external view returns(Notebook memory) {
        return notebooks[notebookId];
    }

    function getUserNotebooks() external view returns(uint256[] memory) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");
        return userOwnedNotebookIds[usersAnkyAddress];
    }

    function getUsersThatOwnNotebook(uint256 notebookId) external view returns(address[] memory) {
        address usersAnkyAddress = ankyAirdrop.getUsersAnkyAddress(msg.sender);
        require(usersAnkyAddress != address(0), "This TBA doesnt exist");
        return ownersOfNotebook[notebookId];
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
