// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// The Great Way is not difficult
// for those who have no preferences.
// When love and hate are both absent
// everything becomes clear and undisguised.
// Make the smallest distinction, however,
// and heaven and earth are set infinitely apart.
//
// If you wish to see the truth
// then hold no opinions for or against anything.
// To set up what you like against what you dislike
// is the disease of the mind.
// When the deep meaning of things is not understood,
// the mind's essential peace is disturbed to no avail.
//
// Hsin Hsin Ming - Third Patriarch of Zen
//
// welcome to the ankyverse
//
// [ in memory of david foster wallace and all the victims of depression ]

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract AnkyGenesis is ERC721Enumerable, Ownable {

    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant PRICE = 0.01618 ether;
    uint256 private _lastMinted = 1;

    address immutable deployer;

    constructor() ERC721("Anky Genesis", "ANKY") {
        deployer = msg.sender;
    }

    function mint() public payable {
        // Check if there is still supply available
        require(_lastMinted <=  MAX_SUPPLY, "The Ankyverse is complete");
        // Check the amount of eth sent
        require(PRICE <= msg.value, "You need to send a bit more of eth.");
        // Check if the address already owns an Anky
        require(balanceOf(msg.sender) == 0, "You already have an Anky");
        // Mint the anky that comes now
        _mint(msg.sender, _lastMinted);
        // Prepare for the next mint
        _lastMinted++;
    }

    // Set the ipfs uri to point to the metadata
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeibawzhxy5iu4jtinkldgczwt43jsufah36m4zl5b7zykfsj5sx3uu/";
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function renounceOwnership() public pure override {
        require(false, "This contract cannot be renounced");
    }
}
