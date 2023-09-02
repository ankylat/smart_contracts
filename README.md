The blockchain background for Anky.

# AnkyNotebooks Smart Contract (/contracts/AnkyNotebooks.sol)

## Overview

The `AnkyNotebooks` smart contract is a crucial part of the Anky ecosystem, allowing users to create, mint, and modify digital notebooks. Each notebook is an NFT (Non-Fungible Token) based on the ERC-1155 standard, with additional functionalities specific to the Anky project.

## Table of Contents

1. [Getting Started](#getting-started)
   - [Dependencies](#dependencies)
   - [Installation](#installation)
2. [Contract Structure](#contract-structure)
3. [Features and Methods](#features-and-methods)
4. [Contributing](#contributing)

---

## Getting Started

### Dependencies

- Solidity ^0.8.0
- OpenZeppelin contracts (ERC1155, ERC1155Supply, Ownable)
- AnkyAirdrop Interface

### Installation

1. Clone this repository.
2. Install the required npm packages:
   `npm install`
3. Compile the contract:
   `truffle compile`

---

## Contract Structure

### Inheritance

- Inherits from `ERC1155Supply` for standard ERC1155 functionality with additional methods for querying the supply of each token ID.
- Inherits from `Ownable` for administrative functionalities.

### Structs

1. **NotebookTemplate**: Stores metadata for notebook templates.

- `creator`: Address of the notebook template creator.
- `metadataURI`: The URI for the metadata.
- `numPages`: Number of pages in the notebook.
- `price`: Cost for minting an instance of this notebook.
- `supply`: Number of available instances to be minted.

2. **NotebookInstance**: Represents an individual notebook that has been minted.

- `templateId`: ID of the `NotebookTemplate` it was minted from.
- `pages`: Mapping to store content on different pages.

### State Variables

- `ankyAirdrop`: An interface to interact with the AnkyAirdrop contract.
- `platformAddress`: The address that receives a percentage of the minting fees.
- `notebookTemplates`: Mapping that stores all the notebook templates.
- `notebookInstances`: Mapping that stores all minted notebook instances.

---

## Features and Methods

1. **constructor**: Initializes contract with the AnkyAirdrop contract address.
2. **createNotebookTemplate**: Creates a new notebook template.

- Checks if the user owns an Anky via AnkyAirdrop interface.
- Checks if the correct fee is sent.

3. **mintNotebookInstance**: Mints instances of a notebook.

- Checks the validity of the template ID.
- Checks if sufficient Ether is sent.
- Updates the supply of the template after minting.

4. **writePage**: Allows owners to write into their notebook instances.

- Validates if the instance exists and if the caller is the owner.

5. **calculatePrice**: Function to calculate the price of minting a notebook based on the number of pages.
6. **\_exists & ownerOf**: Internal functions to check if a notebook instance exists and retrieve its owner.

---

## Contributing

Contributions are always welcome. If you're unfamiliar with the project, please start by reading this README to understand the purpose and structure of the smart contract. Make sure to also check the issues for any open tasks or bugs.

### How to Contribute

1. Fork the repository.
2. Clone your fork locally.
3. Create a new branch for your feature or fix.
4. Make your changes.
5. Push your changes back to your fork on GitHub.
6. Create a pull request.
7. Your pull request will be reviewed and hopefully merged into the main repo!

Thank you for your interest and we look forward to your contributions!
