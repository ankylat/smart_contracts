// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing OpenZeppelin contracts for standard ERC1155 functionality and ownership control
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Importing the AnkyAirdrop interface
import "./interfaces/AnkyAirdrop.sol";

contract AnkyNotebooks is ERC1155Supply, Ownable {

    // Defining state variables
    IAnkyAirdrop public ankyAirdrop; // Interface to interact with the AnkyAirdrop contract
    address public platformAddress;  // Address where the platform's funds will be sent

    // Initialize contract with links to the AnkyAirdrop contract
    constructor(address _ankyAirdrop) ERC1155("https://yourmetadata.uri/{id}.json") {
        ankyAirdrop = IAnkyAirdrop(_ankyAirdrop);  // Setting the AnkyAirdrop contract address
        platformAddress = msg.sender;  // Setting the platform revenue address to the contract deployer
    }

    // Function to mint a new notebook
    function mintNotebook(address to, uint256 notebookId, uint256 amount, uint256 priceInEth) external payable {
        // Check if the sender owns an Anky
        uint256 ankyId = ankyAirdrop.tokenOfOwnerByIndex(msg.sender, 0);  // Fetching the Anky ID of the sender
        require(ankyId != 0, "You must own an Anky to mint a notebook.");

        // Check if the correct payment is sent
        require(msg.value == priceInEth, "Incorrect ETH amount sent.");

        // Mint the notebook
        _mint(to, notebookId, amount, "");  // Using OpenZeppelin's ERC1155 _mint function

        // Distribute funds
        // 10% to the notebook creator
        payable(msg.sender).transfer(priceInEth / 10);
        // 10% stays within the contract
        payable(platformAddress).transfer(priceInEth / 10);
        // 80% goes to the Anky owner's TBA
        address ankyOwnerTBA = ankyAirdrop.getTBAOfToken(ankyId);  // Fetching the TBA address associated with the Anky
        payable(ankyOwnerTBA).transfer((priceInEth * 8) / 10);
    }

    // Function to set a new platform address, only accessible by the contract owner
    function setPlatformAddress(address _platformAddress) external onlyOwner {
        platformAddress = _platformAddress;  // Updating the platform address
    }
}
