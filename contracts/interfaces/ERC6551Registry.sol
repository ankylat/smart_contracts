// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ERC6551Registry {
    // Error: AccountCreationFailed
    error AccountCreationFailed();

    // Event: ERC6551AccountCreated
    event ERC6551AccountCreated(
        address indexed account,
        address indexed implementation,
        bytes32 salt,
        uint256 chainId,
        address indexed tokenContract,
        uint256 tokenId
    );

    // Function: account
    function account(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external view returns (address);

    // Function: createAccount
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address);
}
