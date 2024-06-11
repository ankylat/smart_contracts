// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IKeyGateway {
    function add(uint32 keyType, bytes calldata key, uint8 metadataType, bytes calldata metadata) external;
}
