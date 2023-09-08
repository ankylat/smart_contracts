// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This interface includes all the public and external methods that the AnkyNotebooks contract needs to interact with the AnkyAirdrop contract.
interface IAnkyAirdrop {
    // Retrieves the TBA address associated with a given token ID. Needed to send the 80% of the payment to the Anky owner.
    function getTBAOfToken(uint256 tokenId) external view returns (address);

    // Returns the token ID for the calling address. Needed to check ownership of an Anky.
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    // Check if the address owns an anky
    function balanceOf(address owner) external view returns (uint256);

    // Get the TBA of the anky that is owned by the wallet that is calling the function:
    function getUsersAnkyAddress(address userWallet) external view returns (address);
}
