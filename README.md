# Anky Codebase README

## Overview

This codebase contains the contracts and deployment scripts for the Anky platform. Anky offers an NFT airdrop service and a separate functionality around notebooks. The main contracts of interest are:

- **AnkyAirdrop.sol**: This contract enables airdropping NFTs to users and provides them with token-bound accounts (TBA).
- **AnkyNotebooks.sol**: A contract related to Anky's notebook functionality.
- **ERC6551Registry.sol** & **ERC6551Account.sol**: These contracts are part of the ERC-6551 specification, allowing the creation of TBAs for NFTs.

## Contract Descriptions

### AnkyAirdrop.sol

#### Properties:

- `registry`: A reference to the ERC6551Registry that keeps track of TBAs.
- `ownerToTBA`: A mapping that relates an NFT owner to its associated TBA.

#### Functions:

- `airdropNft(address to)`: Airdrops an NFT to a specified address.
- `createTBAforUsersAnky(address userWallet)`: Creates a TBA for a user's Anky NFT.
- `getTBA(uint256 tokenId)`: Retrieves the TBA address from the Registry using the tokenId.
- `getUsersAnkyAddress(address userWallet)`: Retrieves the TBA address of the NFT that a specified user owns.
- `setTokenURI(uint256 tokenId, string memory newUri)`: Sets or updates the token URI.
- `getTokenURI(uint256 tokenId)`: Retrieves the token URI.

### AnkyTemplates.sol

The AnkyTemplates smart contract serves as a repository for notebook templates created by users owning an Anky. Every template contains metadata like the creator's address, associated metadata URI, the number of pages it has, its price, and the supply. This contract acts as an ERC1155 token, which means each template has an ID and can have multiple supplies. The instancesOfTemplate mapping provides an efficient way to fetch all notebook instances minted from a particular template. This contract ensures that only valid Anky owners can create templates and integrates with the AnkyAirdrop contract to verify Anky ownership.

### AnkyNotebooks.sol

The AnkyNotebooks smart contract is responsible for minting and managing individual notebook instances based on the templates from the AnkyTemplates contract. As an ERC721 token, every notebook instance is unique, having an associated template ID and a status to determine if any writing has occurred. The contract also provides functionalities for users to write content on notebook pages and to check the content of any written page. For every minted notebook, an event is emitted, and the associated costs are shared with the creator. The contract collaborates with the AnkyAirdrop contract to ensure that only valid Anky owners can mint notebooks and write on them.

### ERC6551Registry.sol & ERC6551Account.sol

Contracts that implement the ERC-6551 specification, providing the ability to create TBAs for NFTs.

## Deployment Scripts

### deploy_anky_airdrop_contracts.js

This script handles the deployment of:

- **ERC6551Registry**
- **ERC6551Account**
- **AnkyAirdrop** (with the ERC6551Account's address as the `implementationAddress`)

### deploy_notebooks.js

Deploys the **AnkyNotebooks** contract.

## Development

The development environment uses Hardhat. For local deployments, ensure that you have a local Ethereum node running at `http://127.0.0.1:8545/` and that the `PRIVATE_KEY` environment variable is set for the deploying address.

To run a deployment script:

```bash
npx hardhat run --network localhost scripts/deploy_anky_airdrop_contracts.js
```

Replace the script name with deploy_notebooks.js for the notebook deployment.
