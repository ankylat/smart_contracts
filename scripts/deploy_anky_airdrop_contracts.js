const { ethers } = require('hardhat');
const { deploymentFile } = require('../config');
const storeDeploymentData = require('../storeDeploymentData');

async function deploy() {
  console.log('Starting contract deployment...');
  const baseTokenUri = 'ipfs://QmYeU3QK6jMrYCQ8kSmV7GKqZmEgGaWdoRSV6eB7zqCn2G/';

  const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545/');
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  const AnkyAirdrop = await ethers.deployContract('AnkyAirdrop', [
    Registry.target,
    ERC1155BoundedAccount.target,
    baseTokenUri,
  ]);
  await AnkyAirdrop.waitForDeployment();
  console.log(`AnkyAirdrop deployed at: ${AnkyAirdrop.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deploy().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
