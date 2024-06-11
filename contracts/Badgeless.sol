// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IIdGateway} from "./interfaces/IIdGateway.sol";
import {IStorageRegistry} from "./interfaces/IStorageRegistry.sol";
import {IKeyGateway} from "./interfaces/IKeyGateway.sol";
import {ERC6551Registry} from "./interfaces/ERC6551Registry.sol";

contract Badgeless is ERC721, Ownable {
    uint256 public constant MAX_SUPPLY = 88;
    uint256 public totalSupply;
    uint256 public nftPriceInEthereum = 0.003 ether;

    address public constant idGateway = 0x00000000Fc25870C6eD6b6c7E41Fb078b7656f69;
    address public constant storageRegistry = 0x00000000fcCe7f938e7aE6D3c335bD6a1a7c593D;
    address public immutable keyGateway = 0x00000000fC56947c7E7183f8Ca4B62398CaAdf0B;
    address public constant tokenBoundRegistryAddress = 0x000000006551c19487814612e58FE06813775758;
    address public constant tokenBoundImplementationForCreateAccount = 0x55266d75D1a14E4572138116aF39863Ed6596E7F;
    address public constant tokenBoundImplementationForInitializingAccount = 0x41C8f39463A868d3A88af00cd0fe7102F30E44eC;

    address public thisContractAddress;

    event Mint(address indexed user, uint256 indexed tokenId);
    event FidCreated(uint256 indexed fid, address indexed owner);
    event StorageRented(uint256 indexed fid, uint256 units);

    constructor() ERC721("Badgeless_test", "BLS") {
        thisContractAddress = address(this);
    }

    function mint(
        address recovery,
        uint256 extraStorage,
        uint32 keyType,
        bytes calldata key,
        uint8 metadataType,
        bytes calldata metadata,
        string calldata fname
    ) external payable {
        require(totalSupply < MAX_SUPPLY, "max supply reached");
        uint256 tokenId = totalSupply + 1;

        // Get the price for registering
        uint256 priceOfRegisteringNewFid = IIdGateway(idGateway).price();
        uint256 priceOfOneStorageUnit = IStorageRegistry(storageRegistry).unitPrice();

        require(msg.value >= priceOfRegisteringNewFid + priceOfOneStorageUnit + nftPriceInEthereum, "insufficient eth for paying for everything (registering new fid, storage unit and nft price)");

        address recoveryAddress = createTBA(tokenId);
        // Register Farcaster ID
        (uint256 fid, uint256 overpayment) = IIdGateway(idGateway).register{value: priceOfRegisteringNewFid}(recoveryAddress);
        emit FidCreated(fid, msg.sender);

        // Rent Storage
        IStorageRegistry(storageRegistry).rent{value: priceOfOneStorageUnit}(fid, 1);
        emit StorageRented(fid, 1);

        // Add Signer (This needs to be done off-chain)

        // Mint NFT
        _mint(msg.sender, tokenId);
        totalSupply++;

        emit Mint(msg.sender, tokenId);
    }

    function registerFname(string calldata fname, uint256 fid) internal {
        // Implementation will depend on the Farcaster protocol details.
    }

    function getNftPrice() external view returns (uint256) {
        uint256 priceOfRegisteringNewFid = IIdGateway(idGateway).price();
        uint256 priceOfOneStorageUnit = IStorageRegistry(storageRegistry).unitPrice();
        return priceOfRegisteringNewFid + nftPriceInEthereum + priceOfOneStorageUnit;
    }

    function createTBA(uint256 tokenId) internal returns (address) {
        bytes32 salt = 0;
        uint256 chainId = 10;
        address createdAccountAddress = ERC6551Registry(tokenBoundRegistryAddress).createAccount(tokenBoundImplementationForCreateAccount, salt, chainId, thisContractAddress, tokenId);
        return createdAccountAddress;
    }
}
