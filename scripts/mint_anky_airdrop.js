const hre = require('hardhat');
const fs = require('fs');
const { deploymentFile } = require('../config');
const storeDeploymentData = require('../storeDeploymentData');
const deploymentData = fs.readFileSync(deploymentFile, 'utf-8');
const contracts = JSON.parse(deploymentData);
const contractAddress = contracts[0].AnkyAirdrop.address;

async function mint() {
  console.log(contractAddress);
  //   const ERC721Contract = await hre.ethers.getContractAt(
  //     'Token',
  //     contractAddress
  //   );
  //   console.log('Minting NFT...');
  //   await ERC721Contract.mint(wallet2);
  //   const tokenId = Number(await ERC721Contract.getTokenIds()) - 1;
  //   const owner = await ERC721Contract.ownerOf(tokenId);
  //   console.log(`TokenId ${tokenId} is owned by address:  ${owner}`);
}

mint().catch(error => {
  console.log(error);
  process.exitCode = 1;
});
